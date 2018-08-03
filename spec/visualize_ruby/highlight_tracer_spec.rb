require "visualize_ruby/highlight_tracer"

RSpec.describe VisualizeRuby::HighlightTracer do
  describe "#highlight!" do
    subject {
      described_class.new(builder: builder, executed_events: executed_events)
    }
    let(:executed_events) { [{ line: 3, event: :line }, { line: 6, event: :line }] }
    let(:builder) { VisualizeRuby::Builder.new(ruby_code: ruby_code, in_line_local_method_calls: false).build }

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
      VisualizeRuby::Graphviz.new(builder).to_graph(path: "spec/examples/highlight_tracer_if.png")
      expect(builder.graphs.first.nodes.map { |n| [n.line, n.options.fetch(:color, nil)] }).to eq([[3, :forestgreen], [4, nil], [6, :forestgreen]])
    end

    context "repeated method calls" do
      let(:executed_events) { VisualizeRuby::ExecutionTracer.new(ruby_code: ruby_code, calling_code: calling_code).trace.executed_events }
      let(:calling_code) { <<~RUBY
        MethodCalls.new.caller
      RUBY
      }
      let(:ruby_code) { <<~RUBY
        class MethodCalls
          def caller
            call
            call
            call
          end

          def call
            :call
          end
        end
      RUBY
      }

      it "adds color based executed lines match node lines" do
        subject.highlight!
        VisualizeRuby::Graphviz.new(builder).to_graph(path: "spec/examples/method_caller.png")
        expect(builder.graphs.first.nodes.map { |n| [n.line, n.options.fetch(:color, nil)] }).to eq([[3, :forestgreen], [4, :forestgreen], [5, :forestgreen]])
      end
    end

    context "looping" do
      let(:ruby_code) { <<~RUBY
        class Looping
          def call
            (0..5).each do #3
              paint_town! #4
            end
          end

          def paint_town!
            "hello" #9
          end
        end
      RUBY
      }
      let(:executed_events) {
        [3, 4, 9, 4, 9, 4, 9, 4, 9, 4, 9].map do |line|
          { event: :line, line: line }
        end
      }

      it do
        subject.highlight!
        VisualizeRuby::Graphviz.new(builder).to_graph(path: "spec/examples/highlight_tracer_loop.png")
        expect(builder.graphs.flat_map(&:nodes).map { |n| [n.line, n.touched] }).to eq([[3, 1], [4, 5], [9, 5]])
        expect(builder.graphs.flat_map(&:edges).map { |n| [n.touched] }).to eq([[1], [5], [0], [4]])
      end
    end

    context "gilded rose" do
      let(:ruby_code) { File.read(File.join(File.dirname(__FILE__), "../examples/gilded_rose.rb")) }
      let(:executed_events) { [
          { :line => 4, :event => :call },
          { :line => 5, :event => :line },
          { :line => 6, :event => :line },
          { :line => 7, :event => :line },
          { :line => 8, :event => :return },
          { :line => 10, :event => :call },
          { :line => 11, :event => :line },
          { :line => 12, :event => :line },
          { :line => 13, :event => :line },
          { :line => 14, :event => :line },
          { :line => 34, :event => :line },
          { :line => 35, :event => :line },
          { :line => 37, :event => :line },
          { :line => 54, :event => :return },
      ]
      }

      it do
        subject.highlight!
        VisualizeRuby::Graphviz.new(builder).to_graph(path: "spec/examples/highlight_tracer.png")
        expect(builder.graphs.last.nodes.map { |n| [n.line, n.options.fetch(:color, nil)].compact }.select { |n| n[1] }).to eq([
                                                                                                                                   [11, :forestgreen],
                                                                                                                                   [11, :forestgreen],
                                                                                                                                   [12, :forestgreen],
                                                                                                                                   [13, :forestgreen],
                                                                                                                                   [14, :forestgreen],
                                                                                                                                   [34, :forestgreen],
                                                                                                                                   [35, :forestgreen],
                                                                                                                                   [37, :forestgreen]
                                                                                                                               ])
        expect(builder.graphs.last.edges.map { |e| [e.name, e.options.fetch(:color, nil)] }.select { |n| n[1] }).to eq(
                                                                                                                        [["step: 16", :forestgreen],
                                                                                                                         ["AND step: 8", :forestgreen],
                                                                                                                         ["true step: 10", :forestgreen],
                                                                                                                         ["true step: 12", :forestgreen],
                                                                                                                         ["true step: 14", :forestgreen],
                                                                                                                         ["step: 20", :forestgreen],
                                                                                                                         ["true step: 18", :forestgreen],
                                                                                                                         ["false step: 22", :forestgreen]]
                                                                                                                    )
        expect(builder.graphs.first.nodes.map { |n| [n.line, n.options.fetch(:color, nil)] }).to eq([[5, :forestgreen], [6, :forestgreen], [7, :forestgreen]])
      end
    end
  end
end
