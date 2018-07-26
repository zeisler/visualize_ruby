module VisualizeRuby
  module Touchable
    def post_initialize(**args)
      @touched = 0
      super if defined? super
    end

    def touch(color)
      options.merge!(color: color)
      @touched += 1
    end

    def name
      if [0,1].include?(@touched)
        @name
      else
        "#{@name} (#{@touched})"
      end
    end

    attr_reader :touched
  end
end
