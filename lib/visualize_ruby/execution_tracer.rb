require "tracer"
require "tempfile"

module VisualizeRuby
  class ExecutionTracer
    TRACE_POINT_OPTIONS = [
        :line
    ]
    attr_reader :executed_events
    # @param [String, File, Pathname] ruby_code
    # @param [File, String, Pathname, Proc] calling_code
    # @param [Array<Symbol>] trace_point_options
    def initialize(builder = nil, ruby_code: builder.ruby_code, calling_code:, trace_point_options: TRACE_POINT_OPTIONS)
      @ruby_code           = InputCoercer.new(ruby_code, name: :ruby_code).tap(&:to_file)
      @calling_code        = InputCoercer.new(calling_code, name: :calling_code).tap(&:to_proc)
      @trace_point_options = trace_point_options
      @temp_files          = []
      @executed_events     = []
    end

    def trace
      ruby_code.load_file
      tracer.enable(&calling_code.to_proc)
      self
    ensure
      ruby_code.close!
      calling_code.close!
    end

    private

    attr_reader :trace_point_options,
                :calling_code,
                :temp_files,
                :ruby_code

    def tracer
      @tracer ||= TracePoint.new(*trace_point_options) do |tp|
        if tp.path == ruby_code.to_file.path
          executed_events << { line: tp.lineno, event: tp.event}
        end
      end
    end
  end
end
