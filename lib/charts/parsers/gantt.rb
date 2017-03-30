require 'cgi'

module Charts
  module Parsers
    class Gantt
      # This should match "title" :a1, 0.000, 0.001
      GANTT_LINE_REGEX = %r{
        (?<title>.+)
        (?<group>:\w+)
        ,\s+(?<start>[\w\.]+)
        ,\s+(?<end>[\w\.]+)
      }x

      def self.parse(lines)
        title = 'Gantt Chart'
        date_format = 's.SSS'
        data = []

        while line = lines.shift
          next if line.empty? || line.nil?
          line.strip!

          case line
          when /\Atitle/
            # Line will be like:
            # `title THIS IS MY TITLE`
            # We would want "THIS IS MY TITLE"
            title = line.split(' ')[1..-1].join(' ')
          when /\AdateFormat/
            # Line will be like:
            # `dateFormat s.SSS`
            # We would want "s.SSS"
            date_format = line.split(' ')[1..-1].join(' ')
          else
            match_data = line.match(GANTT_LINE_REGEX)
            data << { title: CGI.escapeHTML(match_data[:title]).strip, start: match_data[:start].to_f, end: match_data[:end].to_f }
          end
        end

        [title, date_format, data]
      end
    end
  end
end
