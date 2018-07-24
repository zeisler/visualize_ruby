module VisualizeRuby
  class Parser
    class Block < Base
      # @return [Array<VisualizeRuby::Node>, Array<VisualizeRuby::Edge>]
      def parse
        iterator, arguments, action = @ast.children
        item                        = arguments.children[0]
        collection, iterator_type   = iterator.to_a
        if enumerable?(collection) || enumerable?(iterator_type)
          enumerable(action, collection, iterator_type, item)
        else
          yield_block(action, item, iterator)
        end
        return nodes, edges
      end

      private

      def yield_block(action, item, on_object)
        nodes << on_object_node = Node.new(ast: on_object)
        nodes << item_node = Node.new(type: :argument, ast: item)
        nodes << action_node = Node.new(ast: action)
        edges << Edge.new(nodes: [on_object_node, item_node])
        edges << Edge.new(nodes: [item_node, action_node], color: "orange")
      end

      def enumerable(action, collection, iterator_type, block_arg)
        nodes << collection_node = Node.new(ast: collection)
        nodes << block_arg_node = Node.new(ast: block_arg, type: :argument) if block_arg
        nodes << iterator_node = Node.new(name: iterator_type, id: AstHelper.new(action).id(description: iterator_type))
        nodes << action_node = Node.new(ast: action)
        edges << Edge.new(nodes: [collection_node, iterator_node])
        if block_arg_node
          edges << Edge.new(nodes: [iterator_node, block_arg_node], color: "blue")
          edges << Edge.new(nodes: [block_arg_node, action_node], color: "blue")
        else
          edges << Edge.new(nodes: [iterator_node, action_node], color: "blue")
        end
        edges << Edge.new(nodes: [action_node, iterator_node], color: "blue", name: "↺")
      end

      def enumerable?(meth)
        meth == :each || Enumerable.instance_methods.include?(meth)
      end
    end
  end
end
