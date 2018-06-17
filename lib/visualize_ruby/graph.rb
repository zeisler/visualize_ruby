module VisualizeRuby
  class Graph
    attr_reader :name, :nodes, :edges

    def initialize(ruby_code:, name: nil)
      @name          = name.to_s
      @nodes, @edges = Parser.new(ruby_code).parse
    end

    def to_hash
      {
          name:  name,
          edges: edges.map(&:to_a),
          nodes: nodes.map(&:to_a),
      }
    end
  end
end
