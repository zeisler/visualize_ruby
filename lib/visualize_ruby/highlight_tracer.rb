module VisualizeRuby
  class HighlightTracer
    OPTIONS = {
        color: :forestgreen
    }

    # @param [VisualizeRuby::Builder::Result] builder
    # @param [Hash{line: Integer, event: Symbol}] executed_events
    # @param [Symbol] color
    def initialize(builder:, executed_events: [], color: OPTIONS.fetch(:color))
      @builder           = builder
      @executed_events   = executed_events
      @color             = color
      @last_touched_node = nil
      @last_touched_edge = nil
      @step_increment    = 0
    end

    # @return [VisualizeRuby::Builder::Result]
    def highlight!
      mark!
      builder
    end

    private

    attr_reader :builder,
                :color,
                :executed_events,
                :last_touched_node,
                :last_touched_edge

    def mark!
      paired_line_events.to_a.each.with_index do |(a, c)|
        build_exe_edge(a, c) unless find_edge(a, c)
      end
    end

    def find_edge(a, c)
      all_edges.detect do |e|
        if e.node_a.line == a && (e.node_b.line || executed_lines.last) == c # end nodes do not have lineno
          check_lineno_connections(e)
          touch(e)
        end
      end
    end

    def step(increment=true)
      if increment
        @step_increment += 1
      else
        @step_increment
      end
    end

    def touch(e, except = nil)
      touched_edge = false
      e.nodes.reject { |n| n == last_touched_node || n == except }.each do |n|
        touched_edge = touch_in_order(e, n, touched_edge)
      end
      touch_edge(e, touched_edge) # if it didn't happen already
    end

    def touch_in_order(e, n, touched_edge)
      if e.node_a == last_touched_node
        touched_edge = touch_edge(e, touched_edge)
        n.touch(color, step: step)
      else
        n.touch(color, step: step)
        touched_edge = touch_edge(e, touched_edge)
      end
      @last_touched_node = n
      touched_edge
    end

    def touch_edge(e, touched_edge)
      if !touched_edge && e != last_touched_edge
        e.touch(color, step: step)
        @last_touched_edge = e
        touched_edge       = true
      end
      touched_edge
    end

    def build_exe_edge(a, c)
      node_a, graph_a = find_node(line: a, graphs: builder.graphs)
      node_b, _ = find_node(line: c, graphs: builder.graphs)
      if node_a && node_b && node_a != node_b
        touch(exe_edge(graph_a, node_a, node_b))
      end
    end

    def find_node(line:, graphs: builder.graphs)
      graphs.each do |graph|
        graph = graph
        node  = graph.nodes.detect { |n| n.line == line }
        return node, graph if node
      end
    end

    def exe_edge(graph_a, node_a, node_b)
      if (exe_edge = all_edges.detect { |e| e.node_b == node_b && e.node_a == node_a })
        exe_edge
      else
        new = Edge.new(nodes: [node_a, node_b], type: :execution, style: :dotted)
        graph_a.edges << new
        new
      end
    end

    # Associated nodes and edges that are on the same line
    def check_lineno_connections(e)
      e.nodes.each do |n|
        touch(n.lineno_connection, e.nodes) if n.lineno_connection
      end
    end

    def all_edges
      builder.graphs.flat_map(&:edges)
    end

    def paired_line_events
      line_events = executed_events.select { |e| e[:event] == :line } + [executed_events.last]
      setup_paring(line_events) do |a, c|
        [line_events[a][:line], line_events[c][:line]]
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
