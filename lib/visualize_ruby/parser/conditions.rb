module VisualizeRuby
  class Parser
    module Conditions
      def set_conditions(condition)
        condition_nodes, condition_edges = Parser.new(ast: condition).parse
        condition_nodes.first.type       = :decision
        nodes.concat(condition_nodes)
        edges.concat(condition_edges)
        condition_nodes
      end
    end
  end
end
