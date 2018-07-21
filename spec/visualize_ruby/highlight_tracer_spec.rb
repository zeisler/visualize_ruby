require "visualize_ruby/highlight_tracer"

RSpec.describe VisualizeRuby::HighlightTracer do
  describe "#highlight!" do
    subject {
      described_class.new(builder: builder, executed_lines: executed_lines)
    }
    let(:executed_lines) { [3, 6] }
    let(:builder) { VisualizeRuby::Builder.new(ruby_code: ruby_code).build }

    let(:ruby_code) { <<~RUBY
      class World
        def testing(color)
          if color == :red
            "red!"
          else
            "not red!"
          end
        end
      end
    RUBY
    }

    it "adds color based executed lines match node lines" do
      subject.highlight!
      expect(builder.graphs.first.nodes.map { |n| [n.line, n.color] }).to eq([[3, :yellow], [4, nil], [6, :yellow]])
    end

    context "gilded rose" do
      let(:ruby_code) { File.read(File.join(File.dirname(__FILE__), "../examples/gilded_rose.rb")) }
      let(:executed_lines) { [4, 5, 6, 7, 8, 10, 11, 12, 13, 14, 34, 35, 37, 54] }

      it do
        subject.highlight!
        VisualizeRuby::Graphviz.new(builder).to_graph(path: "spec/examples/highlight_tracer.png")
        expect(builder.graphs.last.nodes.map { |n| [n.line, n.color].compact }.select { |n| n[1] }).to eq([
                                                                                                              [11, :yellow],
                                                                                                              [11, :yellow],
                                                                                                              [12, :yellow],
                                                                                                              [13, :yellow],
                                                                                                              [14, :yellow],
                                                                                                              [34, :yellow],
                                                                                                              [35, :yellow],
                                                                                                              [37, :yellow]
                                                                                                          ])
        expect(builder.graphs.last.edges.map{|e| [e.name, e.color]}.select { |n| n[1] }).to eq([
                                                                                                   [nil, :yellow],
                                                                                                   ["AND", :yellow],
                                                                                                   ["true", :yellow],
                                                                                                   ["true", :yellow],
                                                                                                   ["true", :yellow],
                                                                                                   [nil, :yellow],
                                                                                                   ["true", :yellow],
                                                                                                   ["false", :yellow]
                                                                                               ])
        expect(builder.graphs.first.nodes.map { |n| [n.line, n.color] }).to eq([[5, :yellow], [6, :yellow], [7, :yellow]])
      end
    end
  end
end
