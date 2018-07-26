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

  let(:build_result) { VisualizeRuby::Builder.new(ruby_code: ruby_code).build }

  it "create the correct DOT lang" do
    expect(described_class.new(build_result).to_graph(format: String).gsub("\t", "  ")).to eq(<<~DOT)
    digraph G {
      label="DoStuff";
      subgraph "cluster_0" {
        label="hungry?";
        style=dotted;
        "stomach.empty? L11"[shape=ellipse, style=rounded, label="stomach.empty?"];
      }
      subgraph "cluster_1" {
        label="start";
        style=dotted;
        "hungry? L3"[shape=diamond, style=rounded, label="hungry?"];
        "eat L4"[shape=ellipse, style=rounded, label="eat"];
        "work L6"[shape=ellipse, style=rounded, label="work"];
        "hungry? L3" -> "stomach.empty? L11"[dir=forward, style=dashed];
        "stomach.empty? L11" -> "eat L4"[label="true", dir=forward, style=dashed];
        "stomach.empty? L11" -> "work L6"[label="false", dir=forward, style=dashed];
      }
    }
    DOT
  end
end
