require "ruby-graphviz"

module VisualizeRuby
  class Graphviz
    attr_reader :graphs, :label

    def initialize(graphs, label: nil)
      @graphs = [*graphs]
      @label  = label
    end

    def to_graph(type: :digraph, **output)
      g          = GraphViz.new(:G, type: type, label: label)
      nodes      = {}
      sub_graphs = graphs.reverse.map.with_index do |graph, index|
        sub_graph = g.add_graph("cluster#{index}", **{ label: graph.name }.reject { |_, v| v.nil? })
        graph.nodes.each do |node|
          nodes[node.name] = sub_graph.add_node(node.name, shape: node.shape)
        end
        [graph, sub_graph]
      end

      sub_graphs.each do |r_graph, g_graph|
        r_graph.edges.each do |edge|
          g_graph.add_edges(nodes[edge.node_a.name], nodes[edge.node_b.name], **{ label: edge.name, dir: edge.dir }.reject { |_, v| v.nil? })
        end
      end
      g.output(output)
    end
  end
end
