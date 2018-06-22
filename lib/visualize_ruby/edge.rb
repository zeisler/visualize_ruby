module VisualizeRuby
  class Edge
    attr_reader :name,
                :node_a,
                :node_b,
                :dir
    def initialize(name: nil, nodes:, dir: :forward)
      @name   = name.to_s if name
      @node_a = nodes[0]
      @node_b = nodes[1]
      @dir    = dir
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

    alias_method :to_s, :inspect
  end
end
