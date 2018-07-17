module VisualizeRuby
  class Parser
    class AstHelper
      def initialize(ast)
        @ast = ast
      end

      def description(ast: @ast)
        return ast unless ast.respond_to?(:type)
        Unparser.unparse(ast)
      end
    end
  end
end
