require "dissociated_introspection"
require "forwardable"

module VisualizeRuby
  class Builder
    # @param [String] ruby_code
    def initialize(ruby_code:, in_line_local_method_calls: true)
      @ruby_code                  = InputCoercer.new(ruby_code, name: :ruby_code)
      @in_line_local_method_calls = in_line_local_method_calls
    end

    def build
      ruby_code  = DissociatedIntrospection::RubyCode.build_from_source(@ruby_code.read)
      ruby_class = DissociatedIntrospection::RubyClass.new(ruby_code)

      if ruby_class.class?
        if @in_line_local_method_calls
          do_in_lining(ruby_class)
        else
          Result.new(
              ruby_code: @ruby_code.input,
              ast:       ruby_code.ast,
              graphs:    build_from_class(ruby_class),
              options:   { label: ruby_class.class_name }
          )
        end
      elsif bare_methods?(ruby_code)
        Result.new(
            ruby_code: @ruby_code.input,
            ast:       ruby_code.ast,
            graphs:    wrap_bare_methods(ruby_code)
        )
      else
        Result.new(
            ruby_code: @ruby_code.input,
            ast:       ruby_code.ast,
            graphs:    [Graph.new(ast: ruby_code.ast)]
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

    def do_in_lining(ruby_class)
      ruby_code_class     = DissociatedIntrospection::RubyCode.build_from_ast(ruby_class.send(:find_class))
      in_lined_ruby       = DissociatedIntrospection::MethodInLiner.new(ruby_code_class, defs: ruby_class.defs).in_line
      reparsed_ruby       = DissociatedIntrospection::RubyCode.build_from_source(in_lined_ruby.source)
      in_lined_ruby_class = DissociatedIntrospection::RubyClass.new(reparsed_ruby)

      Result.new(
          ruby_code: reparsed_ruby.source,
          ast:       reparsed_ruby.ast,
          graphs:    build_from_class(in_lined_ruby_class),
          options:   { label: ruby_class.class_name }
      )
    end

    def build_from_class(ruby_class)
      graphs = build_graphs_by_method(ruby_class)

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

    def edge_search(a: nil, b: nil, edges:)
      edges.select do |e|
        e.node_a == a || e.node_b == b
      end
    end

    def build_graphs_by_method(ruby_class)
      ruby_class.defs.map do |meth|
        Graph.new(
            ruby_code: meth.body.to_s,
            name:      meth.name,
            ast:       meth.body.ast
        )
      end
    end

    def bare_methods?(ruby_code)
      ruby_code.ast.type == :def ||
          ruby_code.ast.type == :begin && ruby_code.ast.children.map(&:type).uniq == [:def]
    end

    def wrap_bare_methods(ruby_code)
      wrapped_ruby_code = <<~Ruby
        class BareMethodsClass
          #{ruby_code.source}
        end
      Ruby
      di_ruby_code = DissociatedIntrospection::RubyCode.build_from_source(wrapped_ruby_code)
      ruby_class   = DissociatedIntrospection::RubyClass.new(di_ruby_code)
      build_from_class(ruby_class)
    end
  end
end
