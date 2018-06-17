module VisualizeRuby
  class Parser
    class Str
      def initialize(ast)
        @ast = ast
      end

      # @return [Array<VisualizeRuby::Node>, Array<VisualizeRuby::Edge>]
      def parse
        return [Node.new(name: AstHelper.new(@ast).description, type: :action)], []
      end
    end
  end
end
