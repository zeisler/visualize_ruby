module VisualizeRuby
  class Parser
    class Begin < Base
      # @return [Array<VisualizeRuby::Node>, Array<VisualizeRuby::Edge>]
      def parse
        last_node = nil
        @ast.children.to_a.compact.reverse.each do |a| # builds tree from bottom up
          _nodes, _edges = Parser.new(ast: a).parse
          edges.concat(_edges.reverse)
          nodes.concat(_nodes.reverse)
          connect_nodes(_edges, _nodes, last_node) if last_node
          last_node = _nodes.first
        end
        return nodes.reverse, edges.reverse
      end

      private

      def connect_nodes(_edges, _nodes, last_node)
        no_top_edge_nodes(_edges, _nodes).each do |n|
          if n.type == :branch_leaf # remove inserted branch leaf, added from Parser::If, and connect to last_node
            # (node-bool->branch_leaf) REPLACE WITH (node-bool->last_node)
            edge          = _edges.detect { |e| e.node_b == n }
            edge.nodes[1] = last_node
            nodes.delete(n)
          else # 1. (-> n) 2. (-> n -> last_node)
            edges << Edge.new(nodes: [n, last_node])
          end
        end
      end

      def no_top_edge_nodes(_edges, _nodes)
        _nodes.select do |n| # ONLY (-> n) NOT (n ->)
          _edges.none? { |e| e.node_a == n }
        end
      end
    end
  end
end
