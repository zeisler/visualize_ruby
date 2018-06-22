module VisualizeRuby
  class Node
    attr_reader :name
    attr_accessor :type
    def initialize(name:, type: :action)
      @name = name.to_s
      @type = type
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
      end
    end

    def shape
      case type
      when :decision
        :diamond
      when :action
        :ellipse
      end
    end

    def inspect
      "#<VisualizeRuby::Node #{type_display} #{name}>"
    end

    alias_method :to_s, :inspect
  end
end
