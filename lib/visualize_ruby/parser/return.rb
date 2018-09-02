module VisualizeRuby
  class Parser
    class Return < Base
      # @return [Array<VisualizeRuby::Node>, Array<VisualizeRuby::Edge>]
      def parse
        nodes, edges = Parser.new(ast: @ast.children[0]).parse
        nodes.last.type = :return
        return [nodes, edges]
      end
    end
  end
end
