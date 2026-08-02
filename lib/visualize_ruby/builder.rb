module VisualizeRuby
  class Builder
    # @param [String] ruby_code
    def initialize(ruby_code:, in_line_local_method_calls: true)
      @ruby_code                  = InputCoercer.new(ruby_code, name: :ruby_code)
      @in_line_local_method_calls = in_line_local_method_calls
    end

    def build
      source = @ruby_code.read
      ast    = Parser.new(source).ast

      if ast.type == :class
        class_name, _superclass, body = ast.children
        definitions = method_definitions(body)
        if @in_line_local_method_calls
          inlined_ast = Parser.new(Unparser.unparse(inline_calls(ast, definitions, []))).ast
          _name, _parent, inlined_body = inlined_ast.children
          Result.new(
            ruby_code: Unparser.unparse(inlined_ast),
            ast:       inlined_ast,
            graphs:    build_graphs(method_definitions(inlined_body)),
            options:   { label: AstHelper.new(class_name).description }
          )
        else
          Result.new(
              ruby_code: source,
              ast:       ast,
              graphs:    build_graphs(definitions),
              options:   { label: AstHelper.new(class_name).description }
          )
        end
      elsif bare_methods?(ast)
        Result.new(
            ruby_code: source,
            ast:       ast,
            graphs:    build_graphs(method_definitions(ast))
        )
      else
        Result.new(
            ruby_code: source,
            ast:       ast,
            graphs:    [Graph.new(ast: ast)]
        )
      end
    end

    class Result
      # @return [Array<VisualizeRuby::Graph>]
      attr_reader :graphs
      # @return [Hash{Symbol => Object}]
      attr_reader :options
      # @return [File]
      attr_reader :ruby_code
      # @return [Parser:AST]
      attr_reader :ast

      def initialize(ruby_code:, graphs:, options: {}, ast:)
        @ruby_code = ruby_code
        @graphs    = graphs
        @options   = options
        @ast       = ast
      end
    end

    private

    def build_graphs(definitions)
      definitions.map do |definition|
        name, _arguments, body = definition.children
        Graph.new(name: name, ast: body)
      end.then { |graphs| connect_method_calls(graphs) }
    end

    def connect_method_calls(graphs)
      graphs.each do |graph|
        graphs.each do |sub_graph|
          sub_graph.nodes.each do |node|
            if node.label == graph.name
              found = sub_graph.edges.select do |e|
                e.node_a == node
              end
              found.first

              graph_edge = Edge.new(
                  nodes: [node, graph.nodes.first],
                  style: :dashed, # indicate method call
              )
              sub_graph.edges.insert(sub_graph.edges.index(found.first) || -1, graph_edge)
              found.each do |edge|
                edge.options(style: :dashed) # indicate method call
                edge.nodes[0] = graph.nodes.first
              end
            end
          end
        end
      end

      graphs
    end

    def bare_methods?(ast)
      ast.type == :def || ast.type == :begin && ast.children.all? { |child| child&.type == :def }
    end

    def method_definitions(ast)
      body = ast.type == :begin ? ast.children : [ast]
      body.select { |child| child&.type == :def }
    end

    def inline_calls(ast, definitions, call_stack)
      return ast unless ast.respond_to?(:type)

      receiver, method_name, *arguments = ast.children if ast.type == :send
      definition = definitions.find { |candidate| candidate.children.first == method_name } if ast.type == :send

      if definition && arguments.empty? && (receiver.nil? || receiver.type == :self) && !call_stack.include?(method_name)
        return inline_calls(definition.children.last, definitions, call_stack + [method_name])
      end

      ast.updated(nil, ast.children.map { |child| inline_calls(child, definitions, call_stack) })
    end
  end
end
