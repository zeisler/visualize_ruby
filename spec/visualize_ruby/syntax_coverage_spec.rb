RSpec.describe "Ruby syntax coverage" do
  def parse(source)
    VisualizeRuby::Parser.new(source).parse
  end

  def assert_valid_graph(source)
    nodes, edges = parse(source)

    expect(nodes).not_to be_empty
    expect(edges).to all(satisfy { |edge| nodes.include?(edge.node_a) && nodes.include?(edge.node_b) })
  end

  it "models while and until loops with an exit and a back edge" do
    nodes, edges = parse(<<~RUBY)
      while ready?
        work
      end
      until finished?
        wait
      end
    RUBY

    expect(nodes.map(&:to_a)).to include(
      [:decision, "ready?"],
      [:action, "work"],
      [:decision, "finished?"],
      [:action, "wait"]
    )
    expect(edges.map(&:to_a)).to include(
      ["ready?", "true", "->", "work"],
      ["work", "↺", "->", "ready?"],
      ["finished?", "false", "->", "wait"],
      ["wait", "↺", "->", "finished?"]
    )
  end

  it "models for loops as decisions with a loop-back edge" do
    nodes, edges = parse(<<~RUBY)
      for item in items
        process(item)
      end
    RUBY

    expect(nodes.map(&:to_a)).to include(
      [:decision, "for item in items"],
      [:action, "process(item)"]
    )
    expect(edges.map(&:to_a)).to include(
      ["for item in items", "true", "->", "process(item)"],
      ["process(item)", "↺", "->", "for item in items"]
    )
  end

  it "keeps terminal statements from flowing into subsequent statements" do
    nodes, edges = parse(<<~RUBY)
      return result
      unreachable
    RUBY

    expect(nodes.map(&:to_a)).to eq([[:return, "result"], [:action, "unreachable"]])
    expect(edges).to be_empty
  end

  it "models rescue, else, and ensure paths without losing protected code" do
    source = <<~RUBY
      begin
        perform
      rescue NetworkError => error
        recover(error)
      else
        finish
      ensure
        cleanup
      end
    RUBY

    nodes, edges = parse(source)

    expect(nodes.map(&:to_a)).to include(
      [:action, "perform"],
      [:decision, "rescue"],
      [:action, "recover(error)"],
      [:action, "finish"],
      [:action, "cleanup"]
    )
    expect(edges.map(&:to_a)).to include(
      ["perform", "success", "->", "finish"],
      ["rescue", "NetworkError", "->", "recover(error)"],
      ["finish", "ensure", "->", "cleanup"],
      ["recover(error)", "ensure", "->", "cleanup"]
    )
  end

  it "models guarded case-in branches and an else branch" do
    nodes, edges = parse(<<~RUBY)
      case response
      in { ok: true, data: } if valid?(data)
        process(data)
      in { error: }
        handle(error)
      else
        fallback
      end
    RUBY

    expect(nodes.map(&:to_a)).to include(
      [:decision, "response"],
      [:action, "process(data)"],
      [:action, "handle(error)"],
      [:action, "fallback"]
    )
    expect(edges.map(&:to_a)).to include(
      ["response", "{ok: true, data:} if valid?(data)", "->", "process(data)"],
      ["response", "{error:}", "->", "handle(error)"],
      ["response", "else", "->", "fallback"]
    )
  end

  it "accepts broad modern expression syntax through safe action fallbacks" do
    sources = [
      "total ||= fetch_total",
      "count += 1",
      "left, right = values",
      "payload => {name:, role:}",
      "options = {timeout:, retries:}",
      "user&.profile&.name",
      "lambda { _1 * 2 }",
      "def relay(...) = target(...)\n",
      "class << service\n  def call = super\nend",
      "<<~TEXT\n  hello \#{name}\nTEXT",
      "%i[one two three]"
    ]

    sources.each { |source| assert_valid_graph(source) }
  end

  it "retains valid graph references across control-flow constructs" do
    assert_valid_graph(<<~RUBY)
      if active?
        while retryable?
          attempt
          break if successful?
        end
      elsif paused?
        wait
      else
        stop
      end
    RUBY
  end
end
