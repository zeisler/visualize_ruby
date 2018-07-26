module VisualizeRuby
  class Graph
    attr_accessor :name, :nodes, :edges

    def initialize(ruby_code: nil, name: nil, ast: nil, **opts)
      @name              = name.to_s if name
      @nodes, @edges     = (ast ? Parser.new(ast: ast) : Parser.new(ruby_code)).parse
      @ast               = ast
      @graph_viz_options = opts
    end

    def options(**args)
      @graph_viz_options.merge!(args)
      @graph_viz_options
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
