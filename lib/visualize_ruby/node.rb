module VisualizeRuby
  class Node
    attr_reader :name, :style, :id
    attr_accessor :type, :order, :id

    def initialize(name: nil, type: :action, style: :rounded, ast: nil, id: nil, order: nil)
      @name  = name || (ast ? AstHelper.new(ast).description : nil)
      @type  = type
      @style = style
      @id    = id || (ast ? AstHelper.new(ast).id : nil)
      @order = order
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
      else
        :box
      end
    end

    def inspect
      "#<VisualizeRuby::Node #{type_display} #{id}>"
    end

    def ==(other)
      other.class == self.class && other.hash == self.hash
    end

    alias_method :eql?, :==

    def hash
      [type, name, style, id].hash
    end

    alias_method :to_s, :inspect
  end
end
