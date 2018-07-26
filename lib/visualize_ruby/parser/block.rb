module VisualizeRuby
  class Parser
    class Block < Base
      # @return [Array<VisualizeRuby::Node>, Array<VisualizeRuby::Edge>]
      def parse
        iterator, arguments, action = @ast.children
        item                        = arguments.children[0]
        collection, iterator_type   = iterator.to_a
        if enumerable?(collection) || enumerable?(iterator_type)
          yield_block(action, item, iterator, "blue", true)
        else
          yield_block(action, item, iterator, "orange", false)
        end
        return nodes, edges
      end

      private

      def yield_block(action, item, on_object, color, enumerable)
        nodes << on_object_node = Node.new(ast: on_object, color: color)
        nodes << item_node = Node.new(type: :argument, ast: item, color: color) if item
        nodes << action_node = Node.new(ast: action, color: color)

        if item_node
          edges << Edge.new(nodes: [on_object_node, item_node], color: color)
          edges << Edge.new(nodes: [item_node, action_node], color: color)
          action_node.lineno_connection = edges.last
        else
          edges << Edge.new(nodes: [on_object_node, action_node], color: color)
        end

        edges << Edge.new(nodes: [action_node, on_object_node], color: color, name: "↺") if enumerable
      end

      def enumerable?(meth)
        meth == :each || Enumerable.instance_methods.include?(meth)
      end
    end
  end
end
