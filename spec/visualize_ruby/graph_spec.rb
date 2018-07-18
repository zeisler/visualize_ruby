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

  describe "uniq edges" do
    let(:ruby_code) {
      <<-RUBY
      if 1+1
        eat
      else
        if 1+1
          eat
        else
          walk
        end
      end
      RUBY
    }

    it "non unique elements" do
      expect(subject.nodes.map(&:to_a)).to eq([[:decision, "1 + 1"], [:action, "eat"], [:decision, "1 + 1"], [:action, "eat"], [:action, "walk"]])
      expect(subject.edges.map(&:to_a)).to eq([["1 + 1", "true", "->", "eat"], ["1 + 1", "false", "->", "1 + 1"], ["1 + 1", "true", "->", "eat"], ["1 + 1", "false", "->", "walk"]])
    end

    it "unique edges" do
      expect(subject.uniq_elements!.nodes.map(&:to_a)).to eq([[:decision, "1 + 1"], [:action, "eat"], [:action, "walk"]])
      expect(subject.uniq_elements!.edges.map(&:to_a)).to eq([["1 + 1", "true", "->", "eat"], ["1 + 1", "false", "->", "1 + 1"], ["1 + 1", "false", "->", "walk"]])
    end
  end
end
