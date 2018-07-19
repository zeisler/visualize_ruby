module VisualizeRuby
  class Parser
    class Case < Base
      # @return [Array<VisualizeRuby::Node>, Array<VisualizeRuby::Edge>]
      def parse
        condition, *_whens, _else = @ast.children
        condition_node = Node.new(ast: condition, type: :decision)
        nodes << condition_node
        _whens.each do |_when|
          edge_name, actions = _when.children
          action_nodes, action_edges = Parser.new(ast: actions).parse
          edges << Edge.new(name:  AstHelper.new(edge_name).description, nodes: [condition_node, action_nodes.first])
          nodes.concat(action_nodes)
          edges.concat(action_edges)
        end
        _else_node = Node.new(ast: _else, type: :action)
        _else_edge = Edge.new(name: "else", nodes: [condition_node, _else_node])
        nodes << _else_node
        edges << _else_edge
        return nodes, edges
      end
    end
  end
end
