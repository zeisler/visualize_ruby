RSpec.describe VisualizeRuby::Graph do
  subject {
    described_class.new(ruby_code: ruby_code, name: :my_method)
  }
  let(:parse) { subject.parse }
  let(:nodes) { parse.first }
  let(:edges) { parse.last }

  describe "parse" do
    let(:ruby_code) {
      <<-RUBY
      if hungry?
        eat
      else
        sleep
      end
      RUBY
    }

    it "adds a name to the graph" do
      expect(subject.name).to eq("my_method")
    end

    it "has nodes" do
      expect(subject.nodes.map(&:class).uniq).to eq([VisualizeRuby::Node])
    end

    it "has edges" do
      expect(subject.edges.map(&:class).uniq).to eq([VisualizeRuby::Edge])
    end
  end
end
