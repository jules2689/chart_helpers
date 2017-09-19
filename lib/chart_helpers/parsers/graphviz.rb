require 'cgi'

module ChartHelpers
  module Parsers
    class Graphviz
      def self.parse(lines)
        graphs = { default_global_data: [] }
        nodes = Set.new
        in_subgraph = false

        while line = lines.shift
          next if line.empty? || line.nil?
          line.strip!

          case line
          when /\Asubgraph/
            subgraph_title = line.split('subgraph')[1..-1].join('subgraph').strip
            graphs[subgraph_title] ||= []
            current_subgraph = subgraph_title
          when /\Aend/
            raise 'Not in subgraph' unless current_subgraph
            current_subgraph = nil
          else
            line = parse_line(line)
            if current_subgraph
              graphs[subgraph_title] << line
            else
              graphs[:default_global_data] << line
            end
            nodes.add(line[:from_node])
            nodes.add(line[:to_node])
          end
        end

        raise 'Never finished subgraph' if in_subgraph
        [graphs, nodes]
      end

      CONNECTOR_REGEX = %r{
        (?<connector>
          --(?<text>\w+)-->|
          -->|
          --(?<text>\w+)---|
          ---|
          -\.(?<text>\w+)\.->|
          -\.->|
          ==(?<text>\w+)===>|
          ==>
        )
      }x

      def self.parse_line(line, date: false)
        match_data = line.match(CONNECTOR_REGEX)
        text = match_data[:text]
        connector = match_data[:connector]
        parts = line.split(connector)

        style = if connector.start_with?('==')
          'bold'
        elsif connector.start_with?('-.')
          'dotted'
        else
          ''
        end

        { 
          from_node: parts.first,
          to_node: parts.last,
          line_text: match_data[:text],
          connector: connector,
          style: style
        }
      end
    end
  end
end
