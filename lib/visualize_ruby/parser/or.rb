module VisualizeRuby
  class Parser
    class Or < Base
      include Conditions
      # @return [Array<VisualizeRuby::Node>, Array<VisualizeRuby::Edge>]
      def parse
        last_node = nil
        @ast.children.reverse.map do |c|
          node = set_conditions(c).first
          edges << Edge.new(name: "OR", nodes: [node, last_node]) if last_node
          last_node = node
        end
        return nodes.reverse, edges
      end
    end
  end
end
