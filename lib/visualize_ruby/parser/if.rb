module VisualizeRuby
  class Parser
    class If < Base
      include Conditions
      # @return [Array<VisualizeRuby::Node>, Array<VisualizeRuby::Edge>]
      def parse
        break_ast

        condition_nodes                = set_conditions(condition)
        on_true_nodes, on_true_edges   = branch(on_true)
        on_false_nodes, on_false_edges = branch(on_false)
        last_condition                 = condition_nodes.last
        on_true_nodes[0]               = on_true_node = (on_true_nodes.first || branch_leaf(last_condition, "true"))
        on_false_nodes[0]              = on_false_node = (on_false_nodes.first || branch_leaf(last_condition, "false"))
        nodes.concat(on_true_nodes)
        nodes.concat(on_false_nodes)
        edges << Edge.new(name: "true", nodes: [last_condition, on_true_node])
        edges << Edge.new(name: "false", nodes: [last_condition, on_false_node])
        edges.concat(on_false_edges)
        edges.concat(on_true_edges)
        return [nodes, edges]
      end

      def branch(on_bool)
        return [], [] unless on_bool
        on_bool_nodes, on_bool_edges = Parser.new(ast: on_bool).parse
        return on_bool_nodes, on_bool_edges
      end

      private

      def branch_leaf(last_condition, type)
        Node.new(
            name: "END",
            type: :branch_leaf,
            id:   "end-#{type}-'#{last_condition.id}'"
        )
      end

      attr_reader :condition, :on_true, :on_false

      def break_ast
        @condition, @on_true, @on_false = @ast.children.to_a
      end
    end
  end
end
