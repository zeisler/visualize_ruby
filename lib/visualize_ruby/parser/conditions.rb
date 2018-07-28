module VisualizeRuby
  class Parser
    module Conditions
      def set_conditions(condition)
        condition_nodes, condition_edges = Parser.new(ast: condition).parse
        condition_nodes.first.type       = :decision
        nodes.concat(condition_nodes.reverse)
        edges.concat(condition_edges)
        condition_nodes
      end

      # @return [Array<VisualizeRuby::Node>, Array<VisualizeRuby::Edge>]
      def parse
        last_node = nil
        @ast.children.reverse.map do |c|
          node = set_conditions(c).last
          if last_node
            edges << Edge.new(name: self.class.name.split("::").last.upcase, nodes: [node, last_node])
            last_node.lineno_connection = edges.last
          end
          last_node = node
          node
        end
        return nodes.reverse, edges
      end
    end
  end
end
