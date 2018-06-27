module VisualizeRuby
  class Parser
    class Base
      def initialize(ast)
        @ast = ast
      end

      private

      def nodes
        @nodes ||= []
      end

      def edges
        @edges ||= []
      end
    end
  end
end
