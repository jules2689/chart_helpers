require 'charts/version'
require 'charts/gantt_chart'
require 'charts/parsers/gantt'
require 'graphviz'

module Charts
  class << self
    def render_chart(chart, output_file)
      chart_lines = chart.split("\n")
      chart_type = chart_lines.shift.strip

      case chart_type
      when /\Agantt\Z/
        parse_gantt(chart_lines, output_file)
      when /\Agraph +\w+ +{/, /\Adigraph\s+\w+\s+{/
        g = GraphViz.parse_string(chart, output: 'svg', file: output_file)
        g.output(svg: output_file)
        g
      when /\Agraph/
        parse_graphviz(chart_lines, output_file)
      else
        raise 'Unsupported chart type declared'
      end
    end

    private

    def parse_gantt(lines, output_file)
      title, date_format, number_format, data = Charts::Parsers::Gantt.parse(lines)

      min = data.collect { |d| d[:start] }.min
      max = data.collect { |d| d[:end] }.max
      scale = (max - min) / 20

      gantt = Charts::GanttChart.new(
        title: title,
        data: data,
        scale: scale,
        date_format: date_format,
        number_format: number_format
      )
      gantt.build(output_file)
      gantt
    end

    def parse_graphviz(lines, output_file)
      parsed_lines, parsed_nodes = Charts::Parsers::Graphviz.parse(lines)
      nodes = {}
      g = GraphViz.new(:G, type: :digraph )

      parsed_nodes.each do |node|
        nodes[node] = g.add_nodes(node)
      end

      parsed_lines[:default_global_data].each do |node_connection|
        opts = { style: node_connection[:style] }
        opts[:label] = node_connection[:line_text] if node_connection[:line_text]
        g.add_edges(nodes[node_connection[:from_node]], nodes[node_connection[:to_node]], opts)
      end

      g.output(svg: output_file)
      g
    end
  end
end
