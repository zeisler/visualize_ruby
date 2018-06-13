require "ruby-graphviz"

module VisualizeRuby
  class Graphviz
    attr_reader :nodes, :edges

    def initialize(nodes, edges)
      @nodes = nodes
      @edges = edges
    end

    def to_graph(type: :digraph, **output)
      g = GraphViz.new(:G, :type => type)
      edges.each do |edge|
        node_a = g.add_node(edge.node_a.name.to_s, shape: edge.node_a.shape)
        node_b = g.add_node(edge.node_b.name.to_s, shape: edge.node_b.shape)
        g.add_edges(node_a, node_b, label: edge.name.to_s, dir: edge.dir)
      end

      g.output(output)
    end
  end
end