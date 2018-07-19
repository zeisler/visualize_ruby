RSpec.describe VisualizeRuby::Graphviz do
  let(:ruby_code) {
    <<-RUBY
    class DoStuff
      def start
        if hungry?
          eat
        else
          work
        end
      end

      def hungry?
        stomach.empty?
      end
    end
    RUBY
  }

  let(:graphs) { VisualizeRuby::Builder.new(ruby_code: ruby_code).build }

  it "create the correct DOT lang" do
    expect(described_class.new(*graphs).to_graph(format: String).gsub("\t", "  ")).to eq(<<~DOT)
    digraph G {
      label="DoStuff";
      subgraph "cluster_0" {
        label="hungry?";
        style=dotted;
        "stomach.empty? L1"[shape=ellipse, style=rounded, label="stomach.empty?"];
      }
      subgraph "cluster_1" {
        label="start";
        style=dotted;
        "hungry? L1"[shape=diamond, style=rounded, label="hungry?"];
        "eat L2"[shape=ellipse, style=rounded, label="eat"];
        "work L4"[shape=ellipse, style=rounded, label="work"];
        "hungry? L1" -> "eat L2"[label="true", dir=forward, style=solid];
        "hungry? L1" -> "work L4"[label="false", dir=forward, style=solid];
        "hungry? L1" -> "stomach.empty? L1"[dir=none, style=dashed];
      }
    }
    DOT
  end
end
