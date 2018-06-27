module VisualizeRuby
  class Parser
    class Send < Base
      # @return [Array<VisualizeRuby::Node>, Array<VisualizeRuby::Edge>]
      def parse
        return [Node.new(name: AstHelper.new(@ast).description, type: :action)], []
      end
    end
  end
end
