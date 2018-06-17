module VisualizeRuby
  class Parser
    class Or
      def initialize(ast)
        @ast = ast
      end

      # @return [Array<VisualizeRuby::Node>, Array<VisualizeRuby::Edge>]
      def parse
        last_node = nil
        edges     = []
        nodes     = @ast.children.reverse.map do |c|
          node = Node.new(name: AstHelper.new(c).description, type: :decision)
          edges << Edge.new(name: "OR", nodes: [node, last_node]) if last_node
          last_node = node
          node
        end.reverse
        return nodes, edges
      end
    end
  end
end
