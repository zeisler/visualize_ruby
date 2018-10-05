module VisualizeRuby
  class InputCoercer
    attr_reader :name, :input

    def initialize(input, name:)
      @input          = input
      @name           = name
    end

    def to_file
      @to_file ||= case input
                   when File
                     input
                   when Pathname
                     File.open(input)
                   when String
                     temp_file
                   else
                     raise ArgumentError, "#{name} was given an unknown type #{input.class}"
                   end
    end

    def normalize_ruby
      InputCoercer.new(Unparser.unparse(::Parser::CurrentRuby.parse(read)), name: name)
    end

    def read
      case input
      when String
        input
      when File, Tempfile, Pathname
        to_file.read
      else
        raise ArgumentError, "#{name} was given an unknown type #{input.class}"
      end
    end

    def close!
      @temp_file.close! if @temp_file
    end

    def temp_file
      @temp_file ||= begin
        file = Tempfile.new(%w(calling_code .rb), File.expand_path(File.join(File.dirname(__FILE__), "../../tmp")))
        file.write(input)
        file.rewind
        file
      end
    end

    def load_file
      load(to_file.path)
    end

    def to_proc
      if input.is_a?(Proc)
        input
      else
        Proc.new { load_file }
      end
    end
  end
end
