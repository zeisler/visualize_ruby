RSpec.describe VisualizeRuby::Parser do
  subject {
    described_class.new(ruby_code).parse
  }
  let(:graph) {
    instance_double(VisualizeRuby::Graph, nodes: nodes, edges: edges, name: "something", options: {})
  }
  let(:nodes) { subject.first }
  let(:edges) { subject.last }

  let(:ruby_code) {
    <<-RUBY
       (bankruptcies.any? do |bankruptcy|
      bankruptcy.closed_date.nil?
    end || bankruptcies.any? do |bankruptcy|
      bankruptcy.closed_date > 2.years.ago
    end)
    RUBY
  }

  it "converts to nodes and edges" do
    expect(nodes.map(&:to_a)).to eq( [[:decision, "bankruptcies.any?"], [:action, "bankruptcy.closed_date.nil?"], [:decision, "bankruptcies.any?"], [:action, "bankruptcy.closed_date > 2.years.ago"]])
    expect(edges.map(&:to_a)).to eq([["bankruptcies.any?", "(arg :bankruptcy)", "->", "bankruptcy.closed_date.nil?"], ["bankruptcy.closed_date.nil?", "↺", "->", "bankruptcies.any?"], ["bankruptcies.any?", "(arg :bankruptcy)", "->", "bankruptcy.closed_date > 2.years.ago"], ["bankruptcy.closed_date > 2.years.ago", "↺", "->", "bankruptcies.any?"], ["bankruptcy.closed_date.nil?", "OR", "->", "bankruptcy.closed_date > 2.years.ago"]])
  end

  it { VisualizeRuby::Graphviz.new(graphs: [graph]).to_graph(path: "spec/examples/block.png") }
end
