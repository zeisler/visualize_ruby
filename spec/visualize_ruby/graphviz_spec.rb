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
        "stomach.empty?"[shape=ellipse, style=rounded];
      }
      subgraph "cluster_1" {
        label="start";
        style=dotted;
        "hungry?"[shape=diamond, style=rounded];
        "eat"[shape=ellipse, style=rounded];
        "work"[shape=ellipse, style=rounded];
        "hungry?" -> "eat"[label="true", dir=forward, style=solid];
        "hungry?" -> "work"[label="false", dir=forward, style=solid];
        "hungry?" -> "stomach.empty?"[dir=none, style=dashed];
      }
    }
    DOT
  end
end
