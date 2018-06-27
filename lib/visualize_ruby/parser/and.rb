module VisualizeRuby
  class Parser
    class And < Base
      # @return [Array<VisualizeRuby::Node>, Array<VisualizeRuby::Edge>]
      def parse
        last_node = nil
        edges     = []
        nodes     = @ast.children.reverse.map do |c|
          node = Node.new(name: c.children.last, type: :decision)
          edges << Edge.new(name: "AND", nodes: [node, last_node]) if last_node
          last_node = node
          node
        end.reverse
        return nodes, edges
      end
    end
  end
end
