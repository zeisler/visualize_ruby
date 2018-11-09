module VisualizeRuby
  class Parser
    class Case < Base
      # @return [Array<VisualizeRuby::Node>, Array<VisualizeRuby::Edge>]
      def parse
        ast_condition_node, *ast_when_nodes, ast_else_node = @ast.children
        condition_node = Node.new(ast: ast_condition_node, type: :decision)
        nodes << condition_node

        ast_when_nodes.each do |ast_when_node|
          edge_name, actions = ast_when_node.children
          action_nodes, action_edges = Parser.new(ast: actions).parse
          edges << Edge.new(name:  AstHelper.new(edge_name).description, nodes: [condition_node, action_nodes.first])
          nodes.concat(action_nodes)
          edges.concat(action_edges)
        end

        if ast_else_node
          else_node = Node.new(ast: ast_else_node, type: :action)
          else_edge = Edge.new(name: "else", nodes: [condition_node, else_node])
          nodes << else_node
          edges << else_edge
        end

        return nodes, edges
      end
    end
  end
end
