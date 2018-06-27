module VisualizeRuby
  class Parser
    class AstHelper
      def initialize(ast)
        @ast = ast
      end

      def description(ast: @ast)
        return ast if ast.is_a?(Symbol)
        Unparser.unparse(ast)
      end
    end
  end
end
