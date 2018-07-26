RSpec.describe VisualizeRuby::Builder do
  describe "#build" do
    subject { described_class.new(ruby_code: ruby_code) }

    context "parses plain ruby body code" do
      let(:ruby_code) {
        <<-RUBY
      if hungry?
        eat
      else
        work
      end
        RUBY
      }

      it "returns a graph" do
        expect(subject.build.graphs.first).to be_an_instance_of(VisualizeRuby::Graph)
      end
    end

    context "when given a class with methods" do
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

      it "returns a graphs" do
        expect(subject.build.graphs.map(&:to_hash)).to eq([
                                                              {
                                                                  name:  "start",
                                                                  edges: [["hungry?", "->", "stomach.empty?"],
                                                                          ["stomach.empty?", "true", "->", "eat"],
                                                                          ["stomach.empty?", "false", "->", "work"]],

                                                                  nodes: [
                                                                             [:decision, "hungry?"],
                                                                             [:action, "eat"],
                                                                             [:action, "work"]
                                                                         ]
                                                              }, {
                                                                  name:  "hungry?",
                                                                  edges: [],
                                                                  nodes: [
                                                                             [:action, "stomach.empty?"]
                                                                         ]
                                                              }
                                                          ])
      end

      it { VisualizeRuby::Graphviz.new(subject.build).to_graph(path: "spec/examples/ruby_class.png") }
    end

    context "when given naked methods" do
      let(:ruby_code) {
        <<-RUBY
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
        RUBY
      }

      it "returns a graphs" do
        expect(subject.build.graphs.map(&:to_hash)).to eq([
                                                              {
                                                                  name:  "start",
                                                                  edges: [["hungry?", "->", "stomach.empty?"],
                                                                          ["stomach.empty?", "true", "->", "eat"],
                                                                          ["stomach.empty?", "false", "->", "work"]],

                                                                  nodes: [
                                                                             [:decision, "hungry?"],
                                                                             [:action, "eat"],
                                                                             [:action, "work"]
                                                                         ]
                                                              }, {
                                                                  name:  "hungry?",
                                                                  edges: [],
                                                                  nodes: [
                                                                             [:action, "stomach.empty?"]
                                                                         ]
                                                              }
                                                          ])
      end

      it { VisualizeRuby::Graphviz.new(subject.build).to_graph(path: "spec/examples/base_methods.png") }

      context "with single method" do
        let(:ruby_code) {
          <<-RUBY
          def start
            if hungry?
              eat
            else
              work
            end
          end
          RUBY
        }

        it "returns a graphs" do
          expect(subject.build.graphs.map(&:to_hash)).to eq([
                                                                {
                                                                    name:  "start",
                                                                    edges: [
                                                                               ["hungry?", "true", "->", "eat"],
                                                                               ["hungry?", "false", "->", "work"],
                                                                           ],
                                                                    nodes: [
                                                                               [:decision, "hungry?"],
                                                                               [:action, "eat"],
                                                                               [:action, "work"]
                                                                           ]
                                                                }
                                                            ])
        end

        it { VisualizeRuby::Graphviz.new(subject.build).to_graph(path: "spec/examples/base_method.png") }
      end
    end

    context "gilded rose" do
      let(:ruby_code) { File.read(File.join(File.dirname(__FILE__), "../examples/gilded_rose.rb")) }

      it { VisualizeRuby::Graphviz.new(subject.build).to_graph(path: "spec/examples/gilded_rose.png") }
    end
  end
end
