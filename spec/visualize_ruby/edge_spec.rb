RSpec.describe VisualizeRuby::Edge do
  let(:nodes) {
    [
        instance_double(VisualizeRuby::Node, name: "node_a"),
        instance_double(VisualizeRuby::Node, name: "node_b")
    ]
  }

  describe "#inspect" do
    it { expect(described_class.new(name: "testing", nodes: nodes).inspect).to eq("#<VisualizeRuby::Edge node_a testing -> node_b>") }
    it { expect(described_class.new(name: "testing", nodes: nodes, dir: :none).inspect).to eq("#<VisualizeRuby::Edge node_a testing - node_b>") }
  end

  describe "#==" do
    let(:edges){[
        described_class.new(name: "testing", nodes: nodes),
        described_class.new(name: "testing", nodes: nodes)
    ]}
    it { expect(edges[0]).to eq(edges[1]) }
  end
end
