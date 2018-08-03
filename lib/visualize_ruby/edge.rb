module VisualizeRuby
  class Edge
    include Namable
    add_names :label
    include Touchable
    include Optionalable
    attr_reader :nodes,
                :dir,
                :style,
                :type,
                :label

    attr_accessor :color,
                  :display

    def initialize(name: nil, nodes:, dir: :forward, type: :default, display: :visual, **opts)
      @label   = name.to_s if name
      @nodes   = nodes
      @dir     = dir
      @style   = style
      @color   = color
      @type    = type
      @display = display
      post_initialize(opts)
    end

    def node_a
      nodes[0]
    end

    def node_b
      nodes[1]
    end

    def to_a
      [
          node_a.name.to_s,
          label,
          direction_symbol,
          node_b.name.to_s,
      ].compact
    end

    def direction_symbol
      case dir
      when :forward
        "->"
      when :none
        "-"
      end
    end

    def inspect
      "#<VisualizeRuby::Edge #{to_a.join(" ")}>"
    end

    def ==(other)
      other.class == self.class && other.hash == self.hash
    end

    alias_method :eql?, :==

    def hash
      [dir, name, nodes.map(&:hash), style, color].hash
    end

    alias_method :to_s, :inspect
  end
end
