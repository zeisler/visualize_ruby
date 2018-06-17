module VisualizeRuby
  class Parser
    class Begin
      def initialize(ast)
        @ast = ast
      end

      # @return [Array<VisualizeRuby::Node>, Array<VisualizeRuby::Edge>]
      def parse
        edges     = []
        last_node = nil
        nodes     = @ast.children.to_a.compact.reverse.map do |a|
          node = Node.new(name: AstHelper.new(a).description, type: :action)
          edges << Edge.new(nodes: [node, last_node]) if last_node
          last_node = node
        end

        return nodes.reverse, edges.reverse
      end
    end
  end
end
