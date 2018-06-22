require "ruby-graphviz"

module VisualizeRuby
  class Graphviz
    attr_reader :graphs, :label

    def initialize(graphs, label: nil)
      @graphs = [*graphs]
      @label  = label
    end

    def to_graph(type: :digraph, **output)
      g          = main_graph(type)
      sub_graphs = sub_graphs(g)

      create_edges(sub_graphs)
      g.output(output)
    end

    private

    def sub_graphs(g)
      graphs.reverse.map.with_index do |graph, index|
        sub_graph = create_sub_graph(g, graph, index)
        create_nodes(graph, sub_graph)
        [graph, sub_graph]
      end
    end

    def nodes
      @nodes ||= {}
    end

    def create_edges(sub_graphs)
      sub_graphs.each do |r_graph, g_graph|
        r_graph.edges.each do |edge|
          g_graph.add_edges(
              nodes[edge.node_a.name],
              nodes[edge.node_b.name],
              **compact({ label: edge.name, dir: edge.dir, style: edge.style })
          )
        end
      end
    end

    def create_sub_graph(g, graph, index)
      g.add_graph(
          "cluster#{index}",
          **compact({ label: graph.name, style: graphs.count == 1 ? :invis : :dotted })
      )
    end

    def create_nodes(graph, sub_graph)
      graph.nodes.each do |node|
        nodes[node.name] = sub_graph.add_node(
            node.name,
            shape: node.shape,
            style: node.style
        )
      end
    end

    def main_graph(type)
      GraphViz.new(:G, type: type, label: label)
    end

    def compact(hash)
      hash.reject { |_, v| v.nil? }
    end
  end
end
