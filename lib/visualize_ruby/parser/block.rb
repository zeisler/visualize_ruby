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
        nodes << on_object_node = Node.new(name: AstHelper.new(on_object).description)
        nodes << item_node = Node.new(name: AstHelper.new(item).description, type: :argument)
        nodes << action_node = Node.new(name: AstHelper.new(action).description)
        edges << Edge.new(nodes: [on_object_node, item_node])
        edges << Edge.new(nodes: [item_node, action_node], color: "orange")
      end

      def enumerable(action, collection, iterator_type, item)
        nodes << collection_node = Node.new(name: AstHelper.new(collection).description)
        nodes << item_node = Node.new(name: AstHelper.new(item).description, type: :argument)
        nodes << iterator_node = Node.new(name: iterator_type)
        nodes << action_node = Node.new(name: AstHelper.new(action).description)
        edges << Edge.new(nodes: [collection_node, iterator_node])
        edges << Edge.new(nodes: [iterator_node, item_node], color: "blue")
        edges << Edge.new(nodes: [item_node, action_node], color: "blue")
        edges << Edge.new(nodes: [action_node, iterator_node], color: "blue", name: "↺")
      end

      def enumerable?(meth)
        meth == :each || Enumerable.instance_methods.include?(meth)
      end
    end
  end
end
