module VisualizeRuby
  class Edge
    attr_reader :name,
                :nodes,
                :dir,
                :style

    attr_accessor :color

    def initialize(name: nil, nodes:, dir: :forward, style: :solid, color: nil)
      @name   = name.to_s if name
      @nodes  = nodes
      @dir    = dir
      @style  = style
      @color  = color
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
          name,
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
