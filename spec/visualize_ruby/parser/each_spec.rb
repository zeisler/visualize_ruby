RSpec.describe VisualizeRuby::Parser::Block do
  subject {
    described_class.new(::Parser::CurrentRuby.parse(ruby_code)).parse
  }
  let(:graph) {
    instance_double(VisualizeRuby::Graph, nodes: nodes, edges: edges, name: "something", options: {})
  }
  let(:nodes) { subject.first }
  let(:edges) { subject.last }

  let(:ruby_code) {
    <<-RUBY
      people.each do |person|
        email(person)
      end
    RUBY
  }

  it "converts to nodes and edges" do
    expect(nodes.map(&:to_a)).to eq([[:action, "people.each"], [:action, "email(person)"]])
    expect(edges.map(&:to_a)).to eq([["people.each", "(arg :person)", "->", "email(person)"], ["email(person)", "↺", "->", "people.each"]])
  end

  it { VisualizeRuby::Graphviz.new(graphs: [graph]).to_graph(path: "spec/examples/each.png") }

  context "map" do
    let(:ruby_code) {
      <<-RUBY
      people.done.map do |person|
        email(person)
      end
      RUBY
    }

    it "converts to nodes and edges" do
      expect(nodes.map(&:to_a)).to eq([[:action, "people.done.map"], [:action, "email(person)"]])
      expect(edges.map(&:to_a)).to eq([["people.done.map", "(arg :person)", "->", "email(person)"], ["email(person)", "↺", "->", "people.done.map"]])
    end
  end

  context "block of code" do
    let(:ruby_code) {
      <<-RUBY
      people.done do |person|
        email(person)
      end
      RUBY
    }

    it "converts to nodes and edges" do
      expect(nodes.map(&:to_a)).to eq([[:action, "people.done"], [:action, "email(person)"]])
      expect(edges.map(&:to_a)).to eq([["people.done", "(arg :person)", "->", "email(person)"]])
    end

    it { VisualizeRuby::Graphviz.new(graphs: [graph]).to_graph(path: "spec/examples/block.png") }
  end

  context "no block args" do
    let(:ruby_code) {
      <<-RUBY
        (0..5).each { puts "Hello!" }
      RUBY
    }

    it "converts to nodes and edges" do
      expect(nodes.map(&:to_a)).to eq([[:action, "(0..5).each"], [:action, "puts(\"Hello!\")"]])
      expect(edges.map(&:to_a)).to eq([["(0..5).each", "->", "puts(\"Hello!\")"], ["puts(\"Hello!\")", "↺", "->", "(0..5).each"]])
    end

    it { VisualizeRuby::Graphviz.new(graphs: [graph]).to_graph(path: "spec/examples/block_no_args.png") }
  end
end
