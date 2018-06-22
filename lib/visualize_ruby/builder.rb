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
        [build_from_class(ruby_class), { label: ruby_class.class_name }]
      elsif bare_methods?(ruby_code)
        wrap_bare_methods(ruby_code)
      else
        Graph.new(ruby_code: @ruby_code)
      end
    end

    private

    def build_from_class(ruby_class)
      graphs = build_graphs_by_method(ruby_class)

      graphs.each do |graph|
        graphs.each do |sub_graph|
          sub_graph.nodes.each do |node|
            sub_graph.edges << Edge.new(
                nodes: [node, graph.nodes.first],
                dir:   :none,
                style: :dashed
            ) if node.name == graph.name
          end
        end
      end

      graphs
    end

    def build_graphs_by_method(ruby_class)
     ruby_class.defs.map do |meth|
        Graph.new(ruby_code: meth.body, name: meth.name)
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
      di_ruby_code  = DissociatedIntrospection::RubyCode.build_from_source(wrapped_ruby_code)
      ruby_class = DissociatedIntrospection::RubyClass.new(di_ruby_code)
      build_from_class(ruby_class)
    end
  end
end
