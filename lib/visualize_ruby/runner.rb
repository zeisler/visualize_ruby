require "active_support/core_ext/hash/compact"

module VisualizeRuby
  class Runner
    # @return [String, File, Pathname, Proc] The code that calls the graphed code.
    attr_accessor :calling_code
    # @return [String, File, Pathname] The code to be graphed.
    attr_accessor :ruby_code
    # @return [Symbol, NilClass, String] To output DOT format as a string use String class as value.
    attr_accessor :output_format
    # @return [String, Pathname] Add the exe name to select a format ie. png, jpg, svg, dot...
    attr_accessor :output_path
    # @param [TrueClass, FalseClass] in line body when calling methods on self. Looks better when tracing execution.
    attr_writer :in_line_local_method_calls
    # @param [TrueClass, FalseClass] Duplicate nodes with the same description are merged to point single node.
    attr_writer :unique_nodes
    # @params [Array<String>, NilClass] When a graph has many sub-graphs only include listed.
    attr_writer :only_graphs
    # @param [String, File]
    # @param [Proc]
    def trace(calling_code = nil, &block)
      @calling_code = calling_code || block
    end

    attr_reader :output

    def run!
      @run ||= begin
        highlight_trace
        @output ||= VisualizeRuby::Graphviz.new(
          builder,
          graphs:       filter_graphs,
          unique_nodes: unique_nodes,
          only_graphs:  only_graphs,
        ).to_graph({ path: output_path, format: output_format }.compact)
      end
      self
    end

    def in_line_local_method_calls
      @in_line_local_method_calls ||= traced?
    end

    def options(opts={})
      opts.each do |key, value|
        public_send("#{key}=", value)
      end
    end

    def graphs
      graphs = builder.graphs.map(&:name).compact
      [builder.options.fetch(:label, "default")].concat(graphs)
    end

    private

    def builder
      @builder ||= VisualizeRuby::Builder.new(
        ruby_code:                  ruby_code,
        in_line_local_method_calls: in_line_local_method_calls
      ).build
    end

    def filter_graphs
      if traced?
        builder.graphs.select do |g|
          g.nodes.any? { |n| n.touched > 0 }
        end
      else
        builder.graphs
      end
    end

    def traced?
      !!calling_code
    end

    def unique_nodes
      @unique_nodes ||= true
    end

    def only_graphs
      @only_graphs ||= nil
    end

    def highlight_trace
      return unless traced?
      executed_events = VisualizeRuby::ExecutionTracer.new(
        builder,
        calling_code: calling_code
      ).trace.executed_events
      VisualizeRuby::HighlightTracer.new(
        builder:         builder,
        executed_events: executed_events
      ).highlight!
    end
  end
end
