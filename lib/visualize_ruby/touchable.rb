module VisualizeRuby
  module Touchable
    def post_initialize(**args)
      self.class.add_names(:touched_display, :step_display)
      @steps   = []
      @touched = 0
      super if defined? super
    end

    def touch(color, step: nil)
      @steps << step
      options.merge!(color: color)
      @touched += 1
    end

    def touched_display
      unless [0, 1].include?(@touched)
        "(called: #{@touched})"
      end
    end

    def step_display
      unless @steps.empty?
        "step: #{@steps.join(", ")}"
      end
    end

    attr_reader :touched
  end
end
