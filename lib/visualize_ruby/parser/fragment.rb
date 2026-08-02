module VisualizeRuby
  class Parser
    # A composable section of a control-flow graph. A fragment keeps the
    # points where execution can enter and continue so larger expressions can
    # be connected without inspecting implementation-specific node arrays.
    class Fragment
      attr_reader :nodes, :edges, :entries, :exits

      def initialize(nodes: [], edges: [], entries: [], exits: [])
        @nodes   = nodes
        @edges   = edges
        @entries = entries
        @exits   = exits
      end

      def self.empty
        new
      end

      def self.node(node, terminal: false)
        new(nodes: [node], entries: [node], exits: terminal ? [] : [node])
      end

      def self.sequence(fragments)
        fragments = fragments.compact.reject { |fragment| fragment.nodes.empty? }
        return empty if fragments.empty?

        nodes   = fragments.flat_map(&:nodes)
        edges   = []
        entries = fragments.first.entries

        fragments.each_with_index do |fragment, index|
          following = fragments[index + 1]
          if following && !fragment.exits.empty?
            # Keep a fragment's outgoing links before its internal edges. This
            # matches the longstanding graph ordering while still allowing an
            # END leaf to be replaced by the following executable node.
            original_length = fragment.edges.length
            link(fragment.edges, nodes, fragment.exits, following.entries)
            edges.concat(fragment.edges.slice!(original_length..) || [])
          end
          edges.concat(fragment.edges)
        end

        new(nodes: nodes, edges: edges, entries: entries, exits: fragments.last.exits)
      end

      def self.combine(*fragments, entries:, exits:)
        new(
          nodes:   fragments.flat_map(&:nodes),
          edges:   fragments.flat_map(&:edges),
          entries: entries,
          exits:   exits
        )
      end

      # Branches with no body use a temporary END node. If a later statement
      # follows, replace that endpoint with the next executable node while
      # preserving its true/false edge label.
      def self.link(edges, nodes, from, to, name: nil, **options)
        sources = from.is_a?(::Array) ? from : [from]
        destinations = to.is_a?(::Array) ? to : [to]

        sources.compact.product(destinations.compact).each do |source, destination|
          if source.type == :branch_leaf
            edge = edges.reverse.find { |candidate| candidate.node_b == source }
            if edge
              edge.nodes[1] = destination
              nodes.delete(source)
              next
            end
          end

          edges << Edge.new(name: name, nodes: [source, destination], **options)
        end
      end
    end
  end
end
