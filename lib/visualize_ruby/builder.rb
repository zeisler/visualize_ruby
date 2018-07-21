require "dissociated_introspection"

module VisualizeRuby
  class Builder
    def initialize(ruby_code:)
      @ruby_code = ruby_code
    end

    def build
      ruby_code  = DissociatedIntrospection::RubyCode.build_from_source(@ruby_code)
      ruby_class = DissociatedIntrospection::RubyClass.new(ruby_code)

      if ruby_class.class?
        Result.new(
            ruby_code: ruby_class.ruby_code.source,
            ast:       ruby_code.ast,
            graphs:    build_from_class(ruby_class),
            options:   { label: ruby_class.class_name }
        )
      elsif bare_methods?(ruby_code)
        Result.new(
            ruby_code: @ruby_code,
            ast:       ruby_code.ast,
            graphs:    wrap_bare_methods(ruby_code)
        )
      else
        Result.new(
            ruby_code: @ruby_code,
            ast:       ruby_code.ast,
            graphs:    [Graph.new(ast: ruby_code.ast).uniq_elements!]
        )
      end
    end

    class Result
      attr_reader :graphs, :options, :ruby_code, :ast

      def initialize(ruby_code:, graphs:, options: {}, ast:)
        @ruby_code = ruby_code
        @graphs    = graphs
        @options   = options
        @ast       = ast
      end

      def build
        self
      end
    end

    private

    def build_from_class(ruby_class)
      graphs = build_graphs_by_method(ruby_class)

      graphs.each do |graph|
        graphs.each do |sub_graph|
          sub_graph.nodes.each do |node|
            if node.name == graph.name
              sub_graph.edges << Edge.new(
                  nodes: [node, graph.nodes.first],
                  dir:   :none,
                  style: :dashed
              )
              graph.nodes.first.owned_by_graph = graph
            end
          end
        end
      end

      graphs
    end

    def build_graphs_by_method(ruby_class)
      ruby_class.defs.map do |meth|
        Graph.new(
            ruby_code: meth.body,
            name:      meth.name,
            ast:       meth.send(:ruby_code).ast.children[2] # method body ast
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
