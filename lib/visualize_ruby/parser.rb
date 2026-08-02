require "parser"
require "parser/current"
require "prism"
require_relative "parser/fragment"
# Retained for callers that instantiate VisualizeRuby::Parser::Block directly.
require_relative "parser/base"
require_relative "parser/block"

module VisualizeRuby
  class Parser
    HANDLERS = {
      and:           :parse_logical,
      or:            :parse_logical,
      begin:         :parse_sequence,
      kwbegin:       :parse_sequence,
      block:         :parse_block,
      case:          :parse_case,
      case_match:    :parse_case_match,
      ensure:        :parse_ensure,
      for:           :parse_for,
      if:            :parse_if,
      itblock:       :parse_itblock,
      numblock:      :parse_numblock,
      rescue:        :parse_rescue,
      return:        :parse_return,
      break:         :parse_break,
      next:          :parse_next,
      redo:          :parse_redo,
      retry:         :parse_retry,
      until:         :parse_loop,
      until_post:    :parse_post_loop,
      while:         :parse_loop,
      while_post:    :parse_post_loop,
    }.freeze

    attr_reader :ast

    def initialize(ruby_code = nil, ast: parse_ruby(ruby_code))
      @ast = ast
    end

    # @return [Array<VisualizeRuby::Node>, Array<VisualizeRuby::Edge>]
    def parse
      fragment = parse_ast(ast)
      [fragment.nodes, fragment.edges]
    end

    private

    # Prism tracks current Ruby grammar and translates it to the parser-gem AST
    # used by this project. New AST types are safely rendered as source nodes
    # until they receive a dedicated control-flow handler.
    def parse_ruby(ruby_code)
      Prism::Translation::Parser.parse(ruby_code)
    end

    def parse_ast(node)
      return Fragment.empty unless ast_node?(node)

      handler = HANDLERS.fetch(node.type, :parse_atomic)
      send(handler, node)
    end

    def parse_sequence(node)
      Fragment.sequence(node.children.filter_map { |child| parse_ast(child) if ast_node?(child) })
    end

    def parse_atomic(node)
      if [:true, :false].include?(node.type)
        Fragment.node(Node.new(name: node.type, type: :action))
      else
        Fragment.node(Node.new(ast: node, type: :action))
      end
    end

    def parse_logical(node)
      left, right = node.children
      left_fragment = condition_fragment(left)
      right_fragment = condition_fragment(right)
      nodes = left_fragment.nodes + right_fragment.nodes
      edges = left_fragment.edges + right_fragment.edges

      Fragment.link(
        edges,
        nodes,
        condition_endpoint(left_fragment),
        condition_endpoint(right_fragment),
        name: node.type.to_s.upcase
      )
      # HighlightTracer follows this edge when two condition nodes appear on
      # the same executed line path. Keep the legacy connection metadata for
      # logical expressions, even though the graph is now built as fragments.
      condition_endpoint(right_fragment).lineno_connection = edges.last

      Fragment.new(
        nodes:   nodes,
        edges:   edges,
        entries: left_fragment.entries,
        exits:   [condition_endpoint(right_fragment)]
      )
    end

    def parse_if(node)
      condition, on_true, on_false = node.children
      condition_fragment = condition_fragment(condition)
      true_fragment = branch_fragment(on_true, condition_fragment, "true")
      false_fragment = branch_fragment(on_false, condition_fragment, "false")
      nodes = condition_fragment.nodes + true_fragment.nodes + false_fragment.nodes
      edges = condition_fragment.edges.dup

      Fragment.link(edges, nodes, condition_fragment.exits, true_fragment.entries, name: "true")
      Fragment.link(edges, nodes, condition_fragment.exits, false_fragment.entries, name: "false")
      edges.concat(false_fragment.edges)
      edges.concat(true_fragment.edges)

      Fragment.new(
        nodes:   nodes,
        edges:   edges,
        entries: condition_fragment.entries,
        exits:   false_fragment.exits + true_fragment.exits
      )
    end

    def parse_loop(node)
      condition, body = node.children
      condition_fragment = condition_fragment(condition)
      body_fragment = parse_ast(body)
      nodes = condition_fragment.nodes + body_fragment.nodes
      edges = condition_fragment.edges.dup
      body_label, exit_label = node.type == :until ? ["false", "true"] : ["true", "false"]
      exit_node = end_node(condition_fragment, exit_label)
      nodes << exit_node

      if body_fragment.entries.empty?
        Fragment.link(edges, nodes, condition_fragment.exits, condition_fragment.entries, name: "↺")
      else
        Fragment.link(edges, nodes, condition_fragment.exits, body_fragment.entries, name: body_label)
      end
      Fragment.link(edges, nodes, condition_fragment.exits, exit_node, name: exit_label)
      edges.concat(body_fragment.edges)
      Fragment.link(edges, nodes, body_fragment.exits, condition_fragment.entries, name: "↺")

      Fragment.new(
        nodes:   nodes,
        edges:   edges,
        entries: condition_fragment.entries,
        exits:   [exit_node]
      )
    end

    def parse_post_loop(node)
      body, condition = node.children
      condition_fragment = condition_fragment(condition)
      body_fragment = parse_ast(body)
      nodes = body_fragment.nodes + condition_fragment.nodes
      edges = body_fragment.edges.dup
      body_label, exit_label = node.type == :until_post ? ["false", "true"] : ["true", "false"]
      exit_node = end_node(condition_fragment, exit_label)
      nodes << exit_node

      Fragment.link(edges, nodes, body_fragment.exits, condition_fragment.entries)
      edges.concat(condition_fragment.edges)
      Fragment.link(edges, nodes, condition_fragment.exits, body_fragment.entries, name: body_label)
      Fragment.link(edges, nodes, condition_fragment.exits, exit_node, name: exit_label)

      Fragment.new(
        nodes:   nodes,
        edges:   edges,
        entries: body_fragment.entries.empty? ? condition_fragment.entries : body_fragment.entries,
        exits:   [exit_node]
      )
    end

    def parse_for(node)
      variables, collection, body = node.children
      loop_node = Node.new(
        name: "for #{description(variables)} in #{description(collection)}",
        type: :decision,
        ast:  node
      )
      body_fragment = parse_ast(body)
      exit_node = end_node(Fragment.node(loop_node), "false")
      nodes = [loop_node] + body_fragment.nodes + [exit_node]
      edges = []

      Fragment.link(edges, nodes, loop_node, body_fragment.entries, name: "true")
      Fragment.link(edges, nodes, loop_node, exit_node, name: "false")
      edges.concat(body_fragment.edges)
      Fragment.link(edges, nodes, body_fragment.exits, loop_node, name: "↺")

      Fragment.new(nodes: nodes, edges: edges, entries: [loop_node], exits: [exit_node])
    end

    def parse_block(node)
      iterator, arguments, body = node.children
      parse_iterating_block(iterator, arguments&.children&.first, body)
    end

    def parse_itblock(node)
      iterator, _parameter, body = node.children
      parse_iterating_block(iterator, :it, body)
    end

    def parse_numblock(node)
      iterator, _count, body = node.children
      parse_iterating_block(iterator, :_1, body)
    end

    def parse_case(node)
      subject, *branches = node.children
      decision = Node.new(name: subject ? description(subject) : "case", type: :decision, ast: node)
      nodes = [decision]
      edges = []
      exits = []
      else_branch = branches.pop

      branches.each do |branch|
        next unless ast_node?(branch) && branch.type == :when

        *patterns, body = branch.children
        body_fragment = parse_ast(body)
        body_fragment = branch_fragment(nil, Fragment.node(decision), description(branch)) if body_fragment.entries.empty?
        nodes.concat(body_fragment.nodes)
        Fragment.link(edges, nodes, decision, body_fragment.entries, name: patterns.map { |pattern| description(pattern) }.join(", "))
        edges.concat(body_fragment.edges)
        exits.concat(body_fragment.exits)
      end

      if ast_node?(else_branch)
        else_fragment = parse_ast(else_branch)
        nodes.concat(else_fragment.nodes)
        Fragment.link(edges, nodes, decision, else_fragment.entries, name: "else")
        edges.concat(else_fragment.edges)
        exits.concat(else_fragment.exits)
      else
        exits << decision
      end

      Fragment.new(nodes: nodes, edges: edges, entries: [decision], exits: exits)
    end

    def parse_case_match(node)
      subject, *branches = node.children
      decision = Node.new(name: description(subject), type: :decision, ast: node)
      nodes = [decision]
      edges = []
      exits = []
      else_branch = branches.reject { |branch| ast_node?(branch) && branch.type == :in_pattern }.last

      branches.each do |branch|
        next unless ast_node?(branch) && branch.type == :in_pattern

        pattern, guard, body = branch.children
        body_fragment = parse_ast(body)
        nodes.concat(body_fragment.nodes)
        label = description(pattern)
        if ast_node?(guard)
          guard_description = description(guard)
          guard = guard_description.start_with?("if") ? guard_description : "if #{guard_description}"
          label = "#{label} #{guard}"
        end
        Fragment.link(edges, nodes, decision, body_fragment.entries, name: label)
        edges.concat(body_fragment.edges)
        exits.concat(body_fragment.exits)
      end

      if ast_node?(else_branch)
        else_fragment = parse_ast(else_branch)
        nodes.concat(else_fragment.nodes)
        Fragment.link(edges, nodes, decision, else_fragment.entries, name: "else")
        edges.concat(else_fragment.edges)
        exits.concat(else_fragment.exits)
      else
        exits << decision
      end

      Fragment.new(nodes: nodes, edges: edges, entries: [decision], exits: exits)
    end

    def parse_rescue(node)
      body, *parts = node.children
      else_body = parts.last unless ast_node?(parts.last) && parts.last.type == :resbody
      rescue_bodies = parts.select { |part| ast_node?(part) && part.type == :resbody }
      body_fragment = parse_ast(body)
      else_fragment = parse_ast(else_body)
      rescue_node = Node.new(name: "rescue", type: :decision, ast: node)
      nodes = body_fragment.nodes + [rescue_node] + else_fragment.nodes
      edges = body_fragment.edges.dup
      exits = []

      if else_fragment.entries.empty?
        exits.concat(body_fragment.exits)
      else
        Fragment.link(edges, nodes, body_fragment.exits, else_fragment.entries, name: "success")
        exits.concat(else_fragment.exits)
      end
      edges.concat(else_fragment.edges)

      rescue_bodies.each do |resbody|
        exceptions, _variable, rescue_body = resbody.children
        rescue_fragment = parse_ast(rescue_body)
        nodes.concat(rescue_fragment.nodes)
        Fragment.link(edges, nodes, rescue_node, rescue_fragment.entries, name: rescue_label(exceptions))
        edges.concat(rescue_fragment.edges)
        exits.concat(rescue_fragment.exits)
      end

      Fragment.new(
        nodes:   nodes,
        edges:   edges,
        entries: body_fragment.entries.empty? ? [rescue_node] : body_fragment.entries,
        exits:   exits
      )
    end

    def parse_ensure(node)
      protected_body, ensure_body = node.children
      protected_fragment = parse_ast(protected_body)
      ensure_fragment = parse_ast(ensure_body)
      nodes = protected_fragment.nodes + ensure_fragment.nodes
      edges = protected_fragment.edges.dup
      Fragment.link(edges, nodes, protected_fragment.exits, ensure_fragment.entries, name: "ensure")
      edges.concat(ensure_fragment.edges)

      Fragment.new(
        nodes:   nodes,
        edges:   edges,
        entries: protected_fragment.entries.empty? ? ensure_fragment.entries : protected_fragment.entries,
        exits:   ensure_fragment.entries.empty? ? protected_fragment.exits : ensure_fragment.exits
      )
    end

    def parse_return(node)
      parse_terminal(node, :return)
    end

    def parse_break(node)
      parse_terminal(node, :terminal)
    end

    def parse_next(node)
      parse_terminal(node, :terminal)
    end

    def parse_redo(node)
      parse_terminal(node, :terminal)
    end

    def parse_retry(node)
      parse_terminal(node, :terminal)
    end

    def parse_terminal(node, type)
      value = node.children.first
      terminal = if ast_node?(value)
                   Node.new(ast: value, type: type)
                 else
                   Node.new(ast: node, type: type)
                 end
      Fragment.node(terminal, terminal: true)
    end

    def parse_iterating_block(iterator, argument, body)
      iterator_node = Node.new(ast: iterator, type: :action, color: enumerable?(iterator) ? "blue" : "orange")
      body_fragment = parse_ast(body)
      nodes = [iterator_node] + body_fragment.nodes
      edges = []
      label = argument.respond_to?(:type) ? argument.to_s : argument

      Fragment.link(edges, nodes, iterator_node, body_fragment.entries, name: label, color: iterator_node.options[:color])
      edges.concat(body_fragment.edges)

      if enumerable?(iterator)
        Fragment.link(edges, nodes, body_fragment.exits, iterator_node, name: "↺", color: iterator_node.options[:color])
        exits = [iterator_node]
      else
        exits = body_fragment.entries.empty? ? [iterator_node] : body_fragment.exits
      end

      Fragment.new(nodes: nodes, edges: edges, entries: [iterator_node], exits: exits)
    end

    def condition_fragment(node)
      fragment = parse_ast(node)
      fragment.nodes.first.type = :decision if fragment.nodes.first
      fragment
    end

    def branch_fragment(node, condition, label)
      fragment = parse_ast(node)
      return fragment unless fragment.entries.empty?

      Fragment.node(end_node(condition, label))
    end

    def condition_endpoint(fragment)
      fragment.nodes.last
    end

    def end_node(fragment, label)
      @end_node_sequence ||= 0
      @end_node_sequence += 1
      source = fragment.nodes.last || ast
      Node.new(
        name: "END",
        type: :branch_leaf,
        id:   "end-#{label}-#{source.id}-#{@end_node_sequence}"
      )
    end

    def enumerable?(iterator)
      return false unless ast_node?(iterator) && iterator.type == :send

      method_name = iterator.children[1]
      method_name == :each || Enumerable.instance_methods.include?(method_name)
    end

    def rescue_label(exceptions)
      return "StandardError" unless ast_node?(exceptions)

      return exceptions.children.map { |exception| description(exception) }.join(", ") if exceptions.type == :array

      description(exceptions)
    end

    def description(node)
      return node.to_s unless ast_node?(node)

      AstHelper.new(node).description
    end

    def ast_node?(node)
      node.respond_to?(:type) && node.respond_to?(:children)
    end
  end
end
