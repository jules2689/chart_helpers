require 'victor'
require 'date'

module Charts
  class GanttChart
    DEFAULT = {
      font_size:         12,
      font_family:       'arial',
      font_weight:       'regular',
      title_font_weight: 'bold',
      font_color:        '#000',
      row_color:         '#9370DB',
      row_height:        30
    }.freeze
    TITLE_TOP_PADDING = 20
    GRID_TOP_PADDING = TITLE_TOP_PADDING + 80

    attr_reader :data, :title, :scale

    def initialize(title:, data:, scale:, width: 2000, height: nil, date_format: nil, number_format: nil, options: {})
      @title = title
      @data = data
      @scale = scale
      @date_format = date_format
      @number_format = number_format
      @options = options

      @max_value = @data.collect { |v| v[:end] }.max
      @max_value = @max_value.to_time if @max_value.is_a?(DateTime)
      @max_value = @max_value.to_f

      @min_value = @data.collect { |v| v[:start] }.min
      @min_value = @min_value.to_time if @min_value.is_a?(DateTime)
      @min_value = @min_value.to_f

      # We aren't guaranteed for our min_value to be 0, so base everything off of the difference
      @diff_value = @max_value - @min_value
      @row_height = setting(:row_height)
      @width = width
      # Height should be one "row_height"" for each row + one for the axis + title
      @height = height || @row_height * (data.size + 1) + 100

      # Cache for text sizes to avoid duplicating work
      @text_sizes = {}
    end

    def build(output)
      svg = Victor::SVG.new(width: @width, height: @height)
      render_title(svg)
      render_grid(svg)
      svg.g(transform: "translate(0, #{TITLE_TOP_PADDING})") do
        @data.each_with_index { |row, i| render_row(svg, row, i + 1) }
      end
      svg.save(output)
    end

    private

    def setting(*keys)
      keys.each do |key|
        res = @options[key]
        return res if res
      end

      keys.each do |key|
        res = DEFAULT[key]
        return res if res
      end

      nil
    end

    def render_title(svg)
      svg.text(
        @title,
        x:           '50%',
        y:           TITLE_TOP_PADDING,
        font_family: setting(:title_font_family, :font_family),
        font_weight: setting(:title_font_weight, :font_weight),
        font_size:   setting(:title_font_size, :font_size),
        fill:        setting(:title_font_color, :font_color),
        style:      'text-anchor: middle;'
      )
    end

    def render_row(svg, row, idx)
      # The width of a particular row can be calculated as a percentage of the difference of the start and end
      # over the maximum end value
      width = ((row[:end] - row[:start]) / @diff_value * @width).ceil

      # The y position will always be row height * index, plus one for the title
      y_pos = idx * (@row_height + 1)

      # Express the x position as a width based change
      x_pos = ((row[:start] - @min_value) / @diff_value * @width).round(2)

      # This rectangle represents the entry in the gantt chart
      svg.rect(
        x: x_pos,
        y: y_pos,
        width: width,
        height: @row_height,
        fill: (row[:row_color] || setting(:line_row_color, :row_color))
      )

      # This is the text of the entry
      if row[:title]
        font_size = row[:font_size] || setting(:line_font_size, :font_size)
        text_width, text_height = size_of_text(font_size, row[:title])
        text_x_pos = x_pos + width + 10

        # If the text will go off the end, then put it in front
        text_x_pos = x_pos - text_width - 10 if text_x_pos + text_width >= @width

        # If the text will start before the chart, make it overlay the rect
        text_x_pos = 10 if text_x_pos < 10

        svg.text(
          row[:title],
          x: text_x_pos.round(2),
          y: y_pos + (@row_height + text_height) / 2, # Attempt to center on the rect
          font_family: row[:font_family] || setting(:line_font_family, :font_family),
          font_weight: row[:font_weight] || setting(:line_font_weight, :font_weight),
          font_size: font_size,
          fill: row[:font_color] || setting(:line_font_color, :font_color)
        )
      end
    end

    def render_grid(svg)
      # The number of ticks we want corresponds to the number of times we can fit our scale
      # in our max value.
      ticks = (@diff_value / @scale).ceil

      # Render a containing element. We translate this down so the title fits.
      svg.g(class: 'grid', transform: "translate(0, #{GRID_TOP_PADDING})") do
        ticks.times do |i|
          x_pos = (100.0 / ticks * i).round(3)
          text = (@scale * i).round(3)
          render_grid_line(svg, "#{x_pos}%", text)
        end
        # Render one more grid line at the end
        x_pos = 100
        text = (@scale * ticks).round(3)
        render_grid_line(svg, "#{x_pos}%", text)
      end
    end

    def render_grid_line(svg, x_pos, text = nil)
      y_pos = @height - @row_height - GRID_TOP_PADDING # Position at the bottom, that is, the height - height of axis (row height) - grid top padding
      font_size = setting(:tick_font_size, :font_size)
      text_to_render = grid_text(text)
      _, text_height = size_of_text(font_size, text_to_render.to_s)
      svg.g(class: 'tick', style: 'opacity: 1; stroke: lightgrey; shape-rendering: crispEdges; stroke-width: 1px') do
        svg.line(y2: -50, y1: y_pos - text_height, x1: x_pos, x2: x_pos) # -50 to extend above the graph
        svg.text(text_to_render, x: x_pos, y: y_pos, font_size: font_size, style: 'stroke: none; fill: black;') unless text.nil?
      end
    end

    def grid_text(text)
      text = if @date_format
        Time.at(@min_value + text).to_datetime.strftime(@date_format)
      elsif @number_format
        format(@number_format, text)
      else
        text.to_s
      end
    end

    def size_of_text(size, string)
      @text_sizes["#{string}-#{size}"] ||= begin
        # This should work on OS X and Ubuntu
        result = estimate_size(size, string)
        width = 0
        height = 0
        width = Regexp.last_match(1).to_f if result =~ /width: ([\d\.]+);/
        height = Regexp.last_match(1).to_f if result =~ /height: ([\d\.]+);/
        [width, height]
      end
    end

    def estimate_size(size, string)
      # EXAMPLE OUTPUT FOR `my_string` AT SIZE 12
      # 2017-03-30T02:03:01-04:00 0:00.030 0.010u 6.9.8 Annotate convert[1787]: annotate.c/RenderFreetype/1468/Annotate
      #   Font /Library/Fonts/Arial.ttf; font-encoding none; text-encoding none; pointsize 12
      # 2017-03-30T02:03:01-04:00 0:00.030 0.010u 6.9.8 Annotate convert[1787]: annotate.c/GetTypeMetrics/888/Annotate
      #   Metrics: text: my_string; width: 52; height: 14; ascent: 11; descent: -3; max advance: 24; bounds: 0.390625,-2  5.875,6; origin: 53,0; pixels per em: 12,12; underline position: -4.5625; underline thickness: 2.34375
      # 2017-03-30T02:03:01-04:00 0:00.030 0.010u 6.9.8 Annotate convert[1787]: annotate.c/RenderFreetype/1468/Annotate
      #   Font /Library/Fonts/Arial.ttf; font-encoding none; text-encoding none; pointsize 12
      `convert xc: -pointsize #{size} -debug annotate -annotate 0 '#{string}' null: 2>&1`
    end
  end
end
