require 'test_helper'
require 'json'
require 'byebug'

class ChartsTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Charts::VERSION
  end

  def test_parsing_gantt_chart
    chart = <<-eos
      gantt
         title file: /gems/bundler-1.14.6/lib/bundler/definition.rb method: converge_dependencies
         dateFormat  s.SSS

         "(@dependencies + @locked_deps.values).each do |dep|" :a1, 0.000, 0.001
         "locked_source = @locked_deps[dep.name] (run 474 times)" :a1, 0.001, 0.002
         "if Bundler.settings[:frozen] && !locked_source.nil? && (run 474 times)" :a1, 0.002, 0.005
         "elsif dep.source (run 474 times)" :a1, 0.005, 0.006
         "dep.source = sources.get(dep.source) (run 142 times)" :a1, 0.006, 0.009
         "if dep.source.is_a?(Source::Gemspec) (run 474 times)" :a1, 0.009, 0.010
         "dependency_without_type = proc {|d| Gem::Dependency.new(d.name, *d.requirement.as_list) } (run 475 times)" :a1, 0.010, 0.026
         "Set.new(@dependencies.map(&dependency_without_type)) != Set.new(@locked_deps.values.map(&dependency_without_type))" :a1, 0.026, 0.027
    eos

    Charts::GanttChart.any_instance.stubs(:estimate_size).returns("width: 37.0; height: 14.0;")

    expected_data = JSON.parse(fixture('gantt.json'), symbolize_names: true)
    Tempfile.open('chart.svg') do |file|
      gantt_chart = Charts.render_chart(chart, file.path)

      assert_equal Charts::GanttChart, gantt_chart.class
      assert_equal expected_data, gantt_chart.data
      assert_equal 'file: /gems/bundler-1.14.6/lib/bundler/definition.rb method: converge_dependencies', gantt_chart.title
      assert_equal 0.00135, gantt_chart.scale
      assert_equal fixture('gantt.svg').strip, File.read(file.path + ".svg").strip
    end
  end

  def test_parsing_gantt_chart_when_rows_start_with_title
    chart = <<-eos
      gantt
      title testing
      dateFormat s.SSS

      title1 :a1, 0.000, 0.001
      title2 :a1, 0.001, 0.005
    eos

    Charts::GanttChart.any_instance.stubs(:estimate_size).returns("width: 37.0; height: 14.0;")

    Tempfile.open('chart.svg') do |file|
      gantt_chart = Charts.render_chart(chart, file.path)

      assert_equal Charts::GanttChart, gantt_chart.class
      assert_equal [{title: "title1", start: 0.0, end: 0.001}, {title: "title2", start: 0.001, end: 0.005}], gantt_chart.data
    end
  end
end
