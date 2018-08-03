RSpec.describe VisualizeRuby::Node do
  describe "#inspect" do
    it {expect(described_class.new(id: "testing").inspect).to eq("#<VisualizeRuby::Node [] testing>")}
    it {expect(described_class.new(id: "testing", type: :decision).inspect).to eq("#<VisualizeRuby::Node <> testing>")}
    it {expect(described_class.new(id: "testing", type: :argument).inspect).to eq("#<VisualizeRuby::Node [> testing>")}
  end

  describe "#name" do
    it {expect(described_class.new(name: "testing").name).to eq("testing")}
    it {expect(described_class.new(name: "testing").tap{|n| n.touch(:red, step: 10)}.name).to eq("testing step: 10")}
    it {expect(described_class.new(name: "testing").tap{|n| n.touch(:red, step: 1); n.touch(:blue, step: 2)}.name).to eq("testing (called: 2) step: 1, 2")}

    context "name_displayer" do
      let(:name_displayer) do
        -> (attr) { attr.map {|k,v| "#{k}: #{v}"}.join(", ") }
      end

      it do
        subject = described_class.new(name: "testing", name_displayer: name_displayer)
        subject.touch(:red, step: 1)
        subject.touch(:red, step: 2)
        expect(subject.name).to eq("label: testing, touched_display: (called: 2), step_display: step: 1, 2")
      end
    end
  end

  describe "#label" do
    it {expect(described_class.new(name: "testing").label).to eq("testing")}
    it {expect(described_class.new(name: "testing").tap{|n| n.touch(:red, step: 10)}.label).to eq("testing")}
  end
end
