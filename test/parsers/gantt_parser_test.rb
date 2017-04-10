require 'test_helper'
require 'json'
require 'byebug'

class GanttParserTest < Minitest::Test
  def test_parsing_gantt_chart
    chart = <<-eos
       title file: /gems/bundler-1.14.6/lib/bundler/definition.rb method: converge_dependencies

       "(@dependencies + @locked_deps.values).each do |dep|" :a1, 0.000, 0.001
       "locked_source = @locked_deps[dep.name] (run 474 times)" :a1, 0.001, 0.002
       "if Bundler.settings[:frozen] && !locked_source.nil? && (run 474 times)" :a1, 0.002, 0.005
       "elsif dep.source (run 474 times)" :a1, 0.005, 0.006
       "dep.source = sources.get(dep.source) (run 142 times)" :a1, 0.006, 0.009
       "if dep.source.is_a?(Source::Gemspec) (run 474 times)" :a1, 0.009, 0.010
       "dependency_without_type = proc {|d| Gem::Dependency.new(d.name, *d.requirement.as_list) } (run 475 times)" :a1, 0.010, 0.026
       "Set.new(@dependencies.map(&dependency_without_type)) != Set.new(@locked_deps.values.map(&dependency_without_type))" :a1, 0.026, 0.027
    eos

    title, date_format, number_format, data = Charts::Parsers::Gantt.parse(chart.split("\n"))

    assert_equal JSON.parse(fixture('gantt.json'), symbolize_names: true), data
    assert_equal 'file: /gems/bundler-1.14.6/lib/bundler/definition.rb method: converge_dependencies', title
    assert_nil date_format
    assert_nil number_format
  end

  def test_parsing_gantt_chart_when_rows_start_with_title
    chart = <<-eos
      title testing

      title1 :a1, 0.000, 0.001
      title2 :a1, 0.001, 0.005
    eos

    title, date_format, number_format, data = Charts::Parsers::Gantt.parse(chart.split("\n"))

    expected_data = [{title: "title1", start: 0.0, end: 0.001}, {title: "title2", start: 0.001, end: 0.005}]
    assert_equal expected_data, data
    assert_equal 'testing', title
    assert_nil date_format
    assert_nil number_format
  end

  def test_parsing_with_number_format
    chart = <<-eos
      title file: /src/github.com/jules2689/bundler/lib/bundler/definition.rb method: initialize
      numberFormat  %.0f%

      "@unlocking = unlock == true || !unlock.empty?" :a1, 0.000, 50.0
      "@dependencies    = dependencies" :a1, 50.0, 100.0
    eos

    title, date_format, number_format, data = Charts::Parsers::Gantt.parse(chart.split("\n"))
    assert_nil date_format
    assert_equal '%.0f%', number_format
  end

  def test_parsing_with_date_format
    chart = <<-eos
      title file: /src/github.com/jules2689/bundler/lib/bundler/definition.rb method: initialize
      dateFormat  %H:%M:%S

      "@unlocking = unlock == true || !unlock.empty?" :a1, 2007-11-19T08:37, 2007-11-19T08:38Z
      "@dependencies    = dependencies" :a1, 2007-11-19T08:38, 2007-11-19T08:40Z
    eos

    _title, date_format, number_format, _data = Charts::Parsers::Gantt.parse(chart.split("\n"))
    assert_equal '%H:%M:%S', date_format
    assert_nil number_format
  end
end
