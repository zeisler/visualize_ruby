require "tracer"
require "tempfile"

module VisualizeRuby
  class ExecutionTracer
    TRACE_POINT_OPTIONS = [
        :line
    ]
    attr_reader :executed_events
    # @param [String, File] ruby_code
    # @param [File, String] calling_code
    # @param [Array<Symbol>] trace_point_options
    def initialize(builder = nil, ruby_code: builder.ruby_code, calling_code:, trace_point_options: TRACE_POINT_OPTIONS)
      @ruby_code           = ruby_code
      @calling_code        = calling_code
      @trace_point_options = trace_point_options
      @temp_files          = []
      @executed_events      = []
    end

    def trace
      load(ruby_file.path)
      tracer.enable { eval(calling_file.read) }
      self
    ensure
      temp_files.each(&:close!)
    end

    private

    attr_reader :trace_point_options

    def tracer
      @tracer ||= TracePoint.new(*trace_point_options) do |tp|
        if tp.path == ruby_file.path
          executed_events << { line: tp.lineno, event: tp.event}
        end
      end
    end

    attr_reader :temp_files

    def temp_file(ruby_code)
      @temp_files ||= []
      file        = Tempfile.new(%w(ruby_file .rb), File.expand_path(File.join(File.dirname(__FILE__), "../../tmp")))
      file.write(ruby_code)
      file.rewind
      @temp_files << file
      file
    end

    def ruby_file
      @ruby_file ||= file!(@ruby_code)
    end

    def calling_file
      @calling_file ||= file!(@calling_code)
    end

    def file!(code)
      code.is_a?(String) ? temp_file(code) : code
    end
  end
end
