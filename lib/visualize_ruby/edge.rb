module VisualizeRuby
  class Edge
    attr_reader :name,
                :node_a,
                :node_b,
                :dir
    def initialize(name: nil, nodes:, dir: :forward)
      @name   = name
      @node_a = nodes[0]
      @node_b = nodes[1]
      @dir    = dir
    end

    def to_a
      [
          node_a.to_sym,
          name,
          direction_symbol,
          node_b.to_sym,
      ].compact
    end

    def direction_symbol
      case dir
      when :forward
        "->"
      end
    end

    def inspect
      "#<VisualizeRuby::Edge #{to_a.join(" ")}>"
    end

    alias_method :to_s, :inspect
  end
end