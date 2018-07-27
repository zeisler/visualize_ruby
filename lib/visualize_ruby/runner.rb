module VisualizeRuby
  class Runner
    # @return [String, File, Pathname, Proc]
    attr_accessor :calling_code
    # @return [String, File, Pathname]
    attr_accessor :ruby_code
    # @return [Symbol, NilClass]
    attr_accessor :output_format
    # @return [String, Pathname]
    attr_accessor :output_path

    # @param [String, File]
    # @param [Proc]
    def trace(calling_code = nil, &block)
      @calling_code = calling_code || block
    end

    def run!
      highlight_trace
      VisualizeRuby::Graphviz.new(builder).to_graph({ path: output_path, format: output_format }.compact)
    end

    private

    def builder
      @builder ||= VisualizeRuby::Builder.new(ruby_code: ruby_code).build
    end

    def highlight_trace
      return unless calling_code
      executed_events = VisualizeRuby::ExecutionTracer.new(builder, calling_code: calling_code).trace.executed_events
      VisualizeRuby::HighlightTracer.new(builder: builder, executed_events: executed_events).highlight!
    end
  end
end
