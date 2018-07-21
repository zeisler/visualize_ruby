RSpec.describe VisualizeRuby::Parser::Block do
  subject {
    described_class.new(::Parser::CurrentRuby.parse(ruby_code)).parse
  }
  let(:graph) {
    instance_double(VisualizeRuby::Graph, nodes: nodes, edges: edges, name: "something")
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
    expect(nodes.map(&:to_a)).to eq([[:action, "people"], [:argument, "person"], [:action, "each"], [:action, "email(person)"]])
    expect(edges.map(&:to_a)).to eq([["people", "->", "each"], ["each", "->", "person"], ["person", "->", "email(person)"], ["email(person)",  "↺","->", "each"]])
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
      expect(nodes.map(&:to_a)).to eq([[:action, "people.done"], [:argument, "person"], [:action, "map"], [:action, "email(person)"]])
      expect(edges.map(&:to_a)).to eq([["people.done", "->", "map"], ["map", "->", "person"], ["person", "->", "email(person)"], ["email(person)", "↺", "->", "map"]])
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
      expect(nodes.map(&:to_a)).to eq([[:action, "people.done"], [:argument, "person"], [:action, "email(person)"]])
      expect(edges.map(&:to_a)).to eq([["people.done", "->", "person"], ["person", "->", "email(person)"]])
    end

    it { VisualizeRuby::Graphviz.new(graphs: [graph]).to_graph(path: "spec/examples/block.png") }
  end
end
