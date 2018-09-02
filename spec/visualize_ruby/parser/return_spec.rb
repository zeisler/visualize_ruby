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
      return plug_in unless plugged_in?
      return replace_bulb if bulb_burt_out?
      repair
    RUBY
  }

  it "converts to nodes and edges" do
    expect(nodes.map(&:to_a)).to eq([[:decision, "plugged_in?"],
                                     [:return, "plug_in"],
                                     [:decision, "bulb_burt_out?"],
                                     [:return, "replace_bulb"],
                                     [:action, "repair"]]
                                 )
    expect(edges.map(&:to_a)).to eq([["plugged_in?", "true", "->", "bulb_burt_out?"], ["plugged_in?", "false", "->", "plug_in"], ["bulb_burt_out?", "true", "->", "replace_bulb"], ["bulb_burt_out?", "false", "->", "repair"]])
  end

  it { VisualizeRuby::Graphviz.new(graphs: [graph]).to_graph(path: "spec/examples/return.png") }
end
