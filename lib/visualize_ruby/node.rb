module VisualizeRuby
  class Node
    attr_reader :name, :style, :id, :line
    attr_accessor :type, :id, :color
    # When a node is part of an an edge from another graph this will be set.
    attr_accessor :owned_by_graph

    def initialize(name: nil, type: :action, style: :rounded, ast: nil, id: nil, color: nil)
      @name  = name || (ast ? AstHelper.new(ast).description : nil)
      @type  = type
      @style = style
      @id    = id || (ast ? AstHelper.new(ast).id : nil)
      @line  = AstHelper.new(ast).first_line
      @color = color
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
