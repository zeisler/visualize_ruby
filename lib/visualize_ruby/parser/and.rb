module VisualizeRuby
  class Parser
    class And < Base
      include Conditions
      # @return [Array<VisualizeRuby::Node>, Array<VisualizeRuby::Edge>]
      def parse
        last_node = nil
        edges     = []
        nodes     = @ast.children.reverse.map do |c|
          node = set_conditions(c).first
          edges << Edge.new(name: "AND", nodes: [node, last_node]) if last_node
          last_node = node
          node
        end.reverse
        return nodes, edges
      end
    end
  end
end
