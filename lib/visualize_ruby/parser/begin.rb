module VisualizeRuby
  class Parser
    class Begin < Base
      # @return [Array<VisualizeRuby::Node>, Array<VisualizeRuby::Edge>]
      def parse
        last_node = nil
        @ast.children.to_a.compact.reverse.each do |a|
          _nodes, _edges = Parser.new(ast: a).parse
          edges.concat(_edges.reverse)
          nodes.concat(_nodes.reverse)
          edges << Edge.new(nodes: [_nodes.first, last_node]) if last_node
          last_node = _nodes.first
        end

        return nodes.reverse, edges.reverse
      end
    end
  end
end
