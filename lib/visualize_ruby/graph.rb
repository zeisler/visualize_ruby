module VisualizeRuby
  class Graph
    attr_reader :name, :nodes, :edges

    def initialize(ruby_code: nil, name: nil, ast: nil)
      @name          = name.to_s if name
      @nodes, @edges = (ast ? Parser.new(ast: ast) : Parser.new(ruby_code)).parse
      @ast = ast
    end

    def to_hash
      {
          name:  name,
          edges: edges.map(&:to_a),
          nodes: nodes.map(&:to_a),
      }
    end

    def uniq_elements!
      @edges = edges.uniq
      @nodes = nodes.uniq
      self
    end
  end
end
