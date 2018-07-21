module VisualizeRuby
  class HighlightTracer
    OPTIONS = {
        color: :yellow
    }

    attr_accessor :executed_lines
    # @param [VisualizeRuby::Builder::Result] builder
    # @param [Array<Integer>] executed_lines
    # @param [Symbol] color
    def initialize(builder:, executed_lines: [], color: OPTIONS.fetch(:color))
      @builder        = builder
      @executed_lines = executed_lines
      @color          = color
    end

    # @return [VisualizeRuby::Builder::Result]
    def highlight!
      builder.build.graphs.each do |graph|
        mark_nodes(graph)
        mark_edges(graph)
      end
      builder
    end

    private

    attr_reader :builder, :color, :executed_lines

    def mark_edges(graph)
      paired_executed_lines.to_a.each do |a, b|
        graph.edges.each do |e| # end nodes do not have lineno
          if e.node_a.line == a && (e.node_b.line || executed_lines.last) == b
            highlight_end_nodes(e)
            e.color = color
          end
        end
      end
    end

    def highlight_end_nodes(e)
      e.node_b.color = color unless e.node_b.line
    end

    def mark_nodes(graph)
      graph.nodes.each do |n|
        n.color = color if executed_lines.include?(n.line)
      end
    end

    def paired_executed_lines
      (0..(executed_lines.length - 2)).to_a.map do |l|
        [executed_lines[l], executed_lines[l + 1]]
      end + same_lineno_pairs
    end

    def same_lineno_pairs
      executed_lines.map do |l|
        [l, l]
      end
    end
  end
end
