require 'charts/version'
require 'charts/gantt_chart'
require 'charts/parsers/gantt'

module Charts
  class << self
    def render_chart(chart, output_file)
      chart_lines = chart.split("\n")
      chart_type = chart_lines.shift.strip

      case chart_type
      when /\Agantt\Z/
        parse_gantt(chart_lines, output_file)
      else
        raise 'Unsupported chart type declared'
      end
    end

    private

    def parse_gantt(lines, output_file)
      # TODO: Use the date format. Right now we only support float based times
      #   should be able to support everything.
      title, _data_format, data = Charts::Parsers::Gantt.parse(lines)

      min = data.collect { |d| d[:start] }.min
      max = data.collect { |d| d[:end] }.max
      scale = (max - min) / 20

      gantt = Charts::GanttChart.new(title: title, data: data, scale: scale)
      gantt.build(output_file)
      gantt
    end
  end
end
