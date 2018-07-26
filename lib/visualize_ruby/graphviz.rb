require "graphviz"

module VisualizeRuby
  class Graphviz
    attr_reader :graphs, :label, :unique_nodes

    def initialize(builder_result = nil, graphs: nil, label: nil, unique_nodes: true)
      @graphs       = graphs || builder_result.graphs
      @label        = builder_result ? builder_result.options[:label] : label
      @unique_nodes = unique_nodes
    end

    def to_graph(format: nil, path: nil)
      build
      if format == String
        str = StringIO.new
        main_graph.dump_graph(str)
        str.string
      else
        ::Graphviz.output(main_graph, path: path, format: format)
      end
    end

    private

    def label
      if graphs.count == 1
        @label = graphs.first.name
      else
        @label
      end
    end

    def build
      create_edges(sub_graphs)
    end

    def sub_graphs
      @sub_graphs ||= graphs.reverse.map.with_index do |graph, index|
        sub_graph = create_sub_graph(graph, index)
        create_nodes(graph, sub_graph)
        [graph, sub_graph]
      end
    end

    def nodes
      @nodes ||= {}
    end

    def node_id(node)
      if unique_nodes
        node.id
      else
        node.name
      end
    end

    def create_edges(sub_graphs)
      sub_graphs.each do |r_graph, g_graph|
        r_graph.edges.each do |edge|
          next unless edge.display == :visual
          ::Graphviz::Edge.new(
              g_graph,
              nodes[node_id(edge.node_a)],
              nodes[node_id(edge.node_b)],
              **compact({ label: edge.name, dir: edge.dir, style: edge.style, **edge.options})
          )
        end
      end
    end

    def create_sub_graph(graph, index)
      main_graph.add_subgraph(
          "cluster_#{index}",
          **compact({ label: graph.name, style: graphs.count == 1 ? :invis : :dotted, **graph.options })
      )
    end

    def create_nodes(graph, sub_graph)
      graph.nodes.each do |node|
        nodes[node_id(node)] = sub_graph.add_node(
            node_id(node),
            compact({
                        shape: node.shape,
                        style: node.style,
                        label: node.name,
                        **node.options
                    })
        )
      end
    end

    def main_graph
      @main_graph ||= ::Graphviz::Graph.new(:G, compact(label: label))
    end

    def compact(hash)
      hash.reject { |_, v| v.nil? }
    end
  end
end
