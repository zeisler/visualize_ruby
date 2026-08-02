RSpec.describe "modern Ruby syntax" do
  def graph_for(source)
    VisualizeRuby::Graph.new(ruby_code: source)
  end

  it "visualizes Ruby 3.4 implicit it blocks" do
    graph = graph_for("items.map { it.upcase }")

    expect(graph.nodes.map(&:to_a)).to eq([
      [:action, "items.map"],
      [:action, "it.upcase"],
    ])
    expect(graph.edges.map(&:to_a)).to eq([
      ["items.map", "it", "->", "it.upcase"],
      ["it.upcase", "↺", "->", "items.map"],
    ])
  end

  it "visualizes pattern-matching branches" do
    graph = graph_for(<<~RUBY)
      case response
      in { ok: true, data: }
        process(data)
      in { error: }
        handle(error)
      end
    RUBY

    expect(graph.nodes.map(&:to_a)).to eq([
      [:decision, "response"],
      [:action, "process(data)"],
      [:action, "handle(error)"],
    ])
    expect(graph.edges.map(&:to_a)).to eq([
      ["response", "{ok: true, data:}", "->", "process(data)"],
      ["response", "{error:}", "->", "handle(error)"],
    ])
  end

  it "parses endless methods and argument forwarding" do
    result = VisualizeRuby::Builder.new(ruby_code: <<~RUBY, in_line_local_method_calls: false).build
      class Reporter
        def log(...) = logger.info(...)
      end
    RUBY

    expect(result.graphs.first.nodes.map(&:to_a)).to eq([[:action, "logger.info(...)"]])
  end
end
