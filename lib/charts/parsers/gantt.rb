require 'cgi'

module Charts
  module Parsers
    class Gantt
      # This should match "title" :a1, 0.000, 0.001
      GANTT_LINE_REGEX = %r{
        (?<title>.+)
        (?<group>:\w+)
        ,\s+(?<start>[[^,]+]+)
        ,\s+(?<end>[[^,]+]+)
      }x

      def self.parse(lines)
        title = 'Gantt Chart'
        date_format = nil
        number_format = nil
        data = []

        while line = lines.shift
          next if line.empty? || line.nil?
          line.strip!

          case line
          when /\Atitle/
            if title == 'Gantt Chart'
              # Line will be like:
              # `title THIS IS MY TITLE`
              # We would want "THIS IS MY TITLE"
              title = line.split(' ')[1..-1].join(' ')
            else
              data << parse_line(line)
            end
          when /\AdateFormat/
            # Line will be like:
            # `dateFormat s.SSS`
            # We would want "s.SSS"
            date_format = line.split(' ')[1..-1].join(' ')
          when /\AnumberFormat/
            # Line will be like:
            # `numberFormat s.SSS`
            # We would want "s.SSS"
            number_format = line.split(' ')[1..-1].join(' ')
          else
            data << parse_line(line, date: !date_format.nil?)
          end
        end

        [title, date_format, number_format, data]
      end

      def self.parse_line(line, date: false)
        match_data = line.match(GANTT_LINE_REGEX)
        start_val, end_val = if date
          [DateTime.parse(match_data[:start]).to_time.to_f, DateTime.parse(match_data[:end]).to_time.to_f]
        else
          [match_data[:start].to_f, match_data[:end].to_f]
        end
        { title: CGI.escapeHTML(match_data[:title]).strip, start: start_val, end: end_val }
      end
    end
  end
end
