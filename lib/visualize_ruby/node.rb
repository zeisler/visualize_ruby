module VisualizeRuby
  class Node
    attr_reader :name, :style
    attr_accessor :type

    def initialize(name:, type: :action, style: :rounded)
      @name  = name.to_s
      @type  = type
      @style = style
    end

    def to_sym
      name.to_s.gsub(" ", "_").to_sym
    end

    def to_a
      [type, name.to_s]
    end

    def type_display
      case type
      when :decision
        "<>"
      when :action
        "[]"
      when :argument
        "[>"
      end
    end

    def shape
      case type
      when :decision
        :diamond
      when :action
        :ellipse
      when :argument
        :box
      end
    end

    def inspect
      "#<VisualizeRuby::Node #{type_display} #{name}>"
    end

    def ==(other)
      other.class == self.class && other.hash == self.hash
    end

    alias_method :eql?, :==

    def hash
      [type, name, style].hash
    end

    alias_method :to_s, :inspect
  end
end
