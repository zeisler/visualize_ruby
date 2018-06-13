require "parser/current"

module VisualizeRuby
  class Parser
    attr_reader :ast

    def initialize(ruby_code = nil, ast: ::Parser::CurrentRuby.parse(ruby_code))
      @ast = ast
    end

    def parse
      merge *Parser.const_get(ast.type.to_s.capitalize).new(ast).parse

      return nodes, edges
    end

    class If
      def initialize(ast)
        @ast = ast
      end

      def parse
        condition, on_true, on_false     = @ast.children.to_a
        nodes                            = []
        edges                            = []
        on_false_nodes, on_false_edges   = Parser.new(ast: on_false).parse
        on_false_node                    = on_false_nodes.first
        condition_nodes, condition_edges = Parser.new(ast: condition).parse
        condition_nodes.first.type       = :decision
        nodes.concat(condition_nodes)
        edges.concat(condition_edges)
        on_true_node = Node.new(name: AstHelper.new(on_true).description)
        nodes << on_true_node
        nodes.concat(on_false_nodes)

        condition_nodes.each do |condition_node|
          edges << Edge.new(name: "true", nodes: [condition_node, on_true_node])
          edges << Edge.new(name: "false", nodes: [condition_node, on_false_node])
        end
        edges.concat(on_false_edges)
        return [nodes, edges]
      end
    end

    class Or
      def initialize(ast)
        @ast = ast
      end

      def parse
        last_node = nil
        edges     = []
        nodes     = @ast.children.reverse.map do |c|
          node = Node.new(name: AstHelper.new(c).description, type: :decision)
          edges << Edge.new(name: "OR", nodes: [node, last_node]) if last_node
          last_node = node
          node
        end.reverse
        return nodes, edges
      end
    end

    class And
      def initialize(ast)
        @ast = ast
      end

      def parse
        last_node = nil
        edges     = []
        nodes     = @ast.children.reverse.map do |c|
          node = Node.new(name: c.children.last, type: :decision)
          edges << Edge.new(name: "AND", nodes: [node, last_node]) if last_node
          last_node = node
          node
        end.reverse
        return nodes, edges
      end
    end

    class AstHelper
      def initialize(ast)
        @ast = ast
      end

      def description(ast: @ast)
        case ast
        when Symbol, String
          ast
        when NilClass
          nil
        else
          ast.children.flat_map do |c|
            description(ast: c)
          end.reject do |c|
            c.nil? || c == :""
          end.join(" ")
        end
      end

    end

    class Begin
      def initialize(ast)
        @ast = ast
      end

      def parse
        edges     = []
        last_node = nil
        nodes     = @ast.children.to_a.compact.reverse.map do |a|
          node = Node.new(name: AstHelper.new(a).description, type: :action)
          edges << Edge.new(nodes: [node, last_node]) if last_node
          last_node = node
        end

        return nodes.reverse, edges.reverse
      end
    end

    class Send
      def initialize(ast)
        @ast = ast
      end

      def parse
        return [Node.new(name: AstHelper.new(@ast).description, type: :action)], []
      end
    end

    class Str
      def initialize(ast)
        @ast = ast
      end

      def parse
        return [Node.new(name: AstHelper.new(@ast).description, type: :action)], []
      end
    end

    def nodes
      @nodes ||= []
    end

    def edges
      @edges ||= []
    end

    def merge(nodes, edges)
      self.nodes.concat(nodes)
      self.edges.concat(edges)
    end
  end
end