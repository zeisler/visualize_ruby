module VisualizeRuby
  class Parser
    class Type < Base
      # @return [Array<VisualizeRuby::Node>, Array<VisualizeRuby::Edge>]
      def parse
        return [Node.new(name: @ast.type, type: :action)], []
      end
    end
  end
end
