RSpec.describe VisualizeRuby::Node do
  describe "#inspect" do
    it {expect(described_class.new(id: "testing").inspect).to eq("#<VisualizeRuby::Node [] testing>")}
    it {expect(described_class.new(id: "testing", type: :decision).inspect).to eq("#<VisualizeRuby::Node <> testing>")}
    it {expect(described_class.new(id: "testing", type: :argument).inspect).to eq("#<VisualizeRuby::Node [> testing>")}
  end
end
