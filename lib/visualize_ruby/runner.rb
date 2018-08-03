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

    # @param [String, File]
    # @param [Proc]
    def trace(calling_code = nil, &block)
      @calling_code = calling_code || block
    end

    def run!
      highlight_trace
      VisualizeRuby::Graphviz.new(
          builder, graphs:
          filter_graphs
      ).to_graph({ path: output_path, format: output_format }.compact)
    end

    def in_line_local_method_calls
      @in_line_local_method_calls ||= traced?
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
