module VisualizeRuby
  class Parser
    class Str < Base
      # @return [Array<VisualizeRuby::Node>, Array<VisualizeRuby::Edge>]
      def parse
        return [Node.new(ast: @ast, type: :action)], []
      end
    end
  end
end
