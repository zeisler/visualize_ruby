module VisualizeRuby
  class Parser
    class AstHelper
      def initialize(ast)
        @ast = ast
      end

      def description(ast: @ast)
        Unparser.unparse(ast)
      end
    end
  end
end
