module VisualizeRuby
  class HighlightTracer
    OPTIONS = {
        color: :forestgreen
    }

    # @param [VisualizeRuby::Builder::Result] builder
    # @param [Hash{line: Integer, event: Symbol}] executed_events
    # @param [Symbol] color
    def initialize(builder:, executed_events: [], color: OPTIONS.fetch(:color))
      @builder         = builder
      @executed_events = executed_events
      @color           = color
    end

    # @return [VisualizeRuby::Builder::Result]
    def highlight!
      mark!
      builder
    end

    private

    attr_reader :builder, :color, :executed_events

    def mark!
      last_touch = nil
      (paired_line_events).to_a.each do |a, b|
        all_edges.detect do |e|
          if e.node_a.line == a && (e.node_b.line || executed_lines.last) == b # end nodes do not have lineno
            touch_nodes(e, except: [last_touch])
            last_touch = e.nodes[1]
            check_lineno_connections(e)
            e.touch(color)
          end
        end || (last_touch = nil)
      end
    end

    def check_lineno_connections(e)
      e.nodes.each do |n|
        if n.lineno_connection
          n.lineno_connection.touch(color)
          touch_nodes(n.lineno_connection, except: e.nodes)
        end
      end
    end

    def touch_nodes(edge, except: [])
      edge.nodes.each { |n| n.touch(color) unless except.include?(n) }
    end

    def all_edges
      @all_edges ||= builder.graphs.flat_map(&:edges)
    end

    def paired_line_events
      line_events = executed_events.select { |e| e[:event] == :line } + [executed_events.last]
      setup_paring(line_events) do |a, b|
        [line_events[a][:line], line_events[b][:line]]
      end
    end

    def setup_paring(array, offset = -2)
      (0..(array.length + offset)).to_a.map do |l|
        yield(l, l + 1)
      end
    end

    def executed_lines
      @executed_lines ||= executed_events.map { |event| event[:line] }
    end
  end
end
