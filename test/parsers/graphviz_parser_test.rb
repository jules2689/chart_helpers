require 'test_helper'
require 'charts/parsers/graphviz'
require 'byebug'

class GraphvizTest < Minitest::Test
  def test_parsing_with_all_arrows
    chart = <<-eos
      A-->B
      B---C
      C--text-->D
      D--text---E
      E-.text.->F
      F-.->G
      G==>H
      H==text===>I
    eos

    parsed_lines, node_set = Charts::Parsers::Graphviz.parse(chart.split("\n"))
    assert_equal Set.new('A'..'I'), node_set

    expected_nodes = [
      { from_node: "A", to_node: "B", line_text: nil,    connector: "-->",        style: "" },
      { from_node: "B", to_node: "C", line_text: nil,    connector: "---",        style: "" },
      { from_node: "C", to_node: "D", line_text: "text", connector: "--text-->",  style: "" },
      { from_node: "D", to_node: "E", line_text: "text", connector: "--text---",  style: "" },
      { from_node: "E", to_node: "F", line_text: "text", connector: "-.text.->",  style: "dotted" },
      { from_node: "F", to_node: "G", line_text: nil,    connector: "-.->",       style: "dotted" },
      { from_node: "G", to_node: "H", line_text: nil,    connector: "==>",        style: "bold" },
      { from_node: "H", to_node: "I", line_text: "text", connector: "==text===>", style: "bold" }
    ]
    assert_equal expected_nodes.size, parsed_lines[:default_global_data].size
    expected_nodes.each_with_index do |node, idx|
      assert_equal node, parsed_lines[:default_global_data][idx]
    end
  end

  def test_parsing_with_subgraphs
    chart = <<-eos
      A-->B
      subgraph A
        B---C
      end
    eos

    parsed_lines, node_set = Charts::Parsers::Graphviz.parse(chart.split("\n"))
    assert_equal Set.new('A'..'C'), node_set

    assert_equal 1, parsed_lines[:default_global_data].size
    assert_equal(
      { from_node: "A", to_node: "B", line_text: nil, connector: "-->", style: "" },
      parsed_lines[:default_global_data].first
    )

    assert_equal 1, parsed_lines['A'].size
    assert_equal(
      { from_node: "B", to_node: "C", line_text: nil, connector: "---", style: "" },
      parsed_lines['A'].first
    )
  end
end