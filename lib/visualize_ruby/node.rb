module VisualizeRuby
  class Node
    include Namable
    add_names :label
    include Touchable
    include Optionalable
    attr_reader :style, :line, :label
    attr_accessor :type, :id, :lineno_connection
    def initialize(name: nil, type: :action, style: :rounded, ast: nil, line: nil, id: nil, **opts)
      @label  = name || (ast ? AstHelper.new(ast).description : nil)
      @type  = type
      @style = style
      @id    = id || (ast ? AstHelper.new(ast).id : @label)
      @line  = line || AstHelper.new(ast).first_line
      post_initialize(opts)
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
