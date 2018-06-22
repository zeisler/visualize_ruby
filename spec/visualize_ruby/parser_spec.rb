RSpec.describe VisualizeRuby::Parser do
  subject {
    described_class.new(ruby_code).parse
  }
  let(:graph) {
    instance_double(VisualizeRuby::Graph, nodes: nodes, edges: edges, name: "something")
  }
  let(:nodes) { subject.first }
  let(:edges) { subject.last }

  context "links actions" do
    let(:ruby_code) {
      <<-RUBY
      eat(:breakfast)
      brush(:teeth)
      drive(:work)
      RUBY
    }

    it "converts to nodes and edges" do
      expect(nodes.map(&:to_a)).to eq([[:action, "eat(:breakfast)"], [:action, "brush(:teeth)"], [:action, "drive(:work)"]])
      expect(edges.map(&:to_a)).to eq([["eat(:breakfast)", "->", "brush(:teeth)"], ["brush(:teeth)", "->", "drive(:work)"]])
    end

    it "returns [Array[VisualizeRuby::Node], Array[VisualizeRuby::Edge]" do
      expect(subject.flatten.map(&:class).uniq).to eq([VisualizeRuby::Node, VisualizeRuby::Edge])
    end

    it { VisualizeRuby::Graphviz.new(graph).to_graph(png: "spec/examples/link_actions.png") }
  end

  context "condition" do
    context "OR" do
      let(:ruby_code) {
        <<-RUBY
      person.hungry? || starving?
        RUBY
      }

      it "converts to nodes and edges" do
        expect(nodes.map(&:to_a)).to eq([[:decision, "person.hungry?"], [:decision, "starving?"]])
        expect(edges.map(&:to_a)).to eq([["person.hungry?", "OR", "->", "starving?"]])
      end

      it { VisualizeRuby::Graphviz.new(graph).to_graph(png: "spec/examples/or.png") }
    end

    context "AND" do
      let(:ruby_code) {
        <<-RUBY
      hungry? && starving?
        RUBY
      }

      it "converts to nodes and edges" do
        expect(nodes.map(&:to_a)).to eq([[:decision, "hungry?"], [:decision, "starving?"]])
        expect(edges.map(&:to_a)).to eq([["hungry?", "AND", "->", "starving?"]])
      end

      it { VisualizeRuby::Graphviz.new(graph).to_graph(png: "spec/examples/and.png") }
    end
  end

  context "if statement" do
    let(:ruby_code) {
      <<-RUBY
      if hungry?
        eat
      else
        sleep
      end
      RUBY
    }

    it "converts to nodes and edges" do
      expect(nodes.map(&:to_a)).to eq([[:decision, "hungry?"], [:action, "eat"], [:action, "sleep"]])
      expect(edges.map(&:to_a)).to eq([["hungry?", "true", "->", "eat"], ["hungry?", "false", "->", "sleep"]])
    end

    it { VisualizeRuby::Graphviz.new(graph).to_graph(png: "spec/examples/if_statement.png") }

    context "with condition" do
      let(:ruby_code) {
        <<-RUBY
        if hungry? || alone?
          eat
        else
          sleep
        end
        RUBY
      }

      it "converts to nodes and edges" do
        expect(nodes.map(&:to_a)).to eq([
                                            [:decision, "hungry?"],
                                            [:decision, "alone?"],
                                            [:action, "eat"],
                                            [:action, "sleep"]
                                        ])
        expect(edges.map(&:to_a)).to eq([
                                            ["hungry?", "OR", "->", "alone?"],
                                            ["hungry?", "true", "->", "eat"],
                                            ["hungry?", "false", "->", "sleep"],
                                            ["alone?", "true", "->", "eat"],
                                            ["alone?", "false", "->", "sleep"]
                                        ])
      end

      it { VisualizeRuby::Graphviz.new(graph).to_graph(png: "spec/examples/if_with_condition.png") }
    end

    context "with elsif" do
      let(:ruby_code) {
        <<-RUBY
        if project.done?
          go_on_vacation
        elsif project.blocked?
          eat(:donuts)
        else
          sleep
        end
        RUBY
      }

      it "converts to nodes and edges" do
        expect(nodes.map(&:to_a)).to eq([
                                            [:decision, "project.done?"],
                                            [:action, "go_on_vacation"],
                                            [:decision, "project.blocked?"],
                                            [:action, "eat(:donuts)"],
                                            [:action, "sleep"]
                                        ])
        expect(edges.map(&:to_a)).to eq([
                                            ["project.done?", "true", "->", "go_on_vacation"],
                                            ["project.done?", "false", "->", "project.blocked?"],
                                            ["project.blocked?", "true", "->", "eat(:donuts)"],
                                            ["project.blocked?", "false", "->", "sleep"]
                                        ])
      end

      it { VisualizeRuby::Graphviz.new(graph).to_graph(png: "spec/examples/elsif.png") }

      context "complex example" do
        let(:ruby_code) {
          <<-RUBY
        if data_unavailable?
          "unavailable"
        elsif exceptional_mortgage_matching?
          exception(:undetermined_mortgage_balance)
        elsif declinable_mortgage_payment_history?
          "decline"
        elsif manner_of_payment_codes.include?(:decline)
          "decline"
        elsif manner_of_payment_codes.include?(:exception)
          exception(:negative_mortgage_mop_code)
        else
          "approved"
        end
          RUBY
        }

        it { VisualizeRuby::Graphviz.new(graph).to_graph(png: "spec/examples/complex_logic.png") }
      end

      context "with linked actions" do
        let(:ruby_code) {
          <<-RUBY
        if project.done?
          eat(:donuts)
          clean(:kitchen)
        end
          RUBY
        }

        it "converts to nodes and edges" do
          expect(nodes.map(&:to_a)).to eq([
                                              [:decision, "project.done?"],
                                              [:action, "eat(:donuts)"],
                                              [:action, "clean(:kitchen)"]
                                          ])
          expect(edges.map(&:to_a)).to eq([
                                              ["project.done?", "true", "->", "eat(:donuts)"],
                                              ["eat(:donuts)", "->", "clean(:kitchen)"]
                                          ])
        end

        it { VisualizeRuby::Graphviz.new(graph).to_graph(png: "spec/examples/if_with_linked_actions.png") }
      end
    end

    context "nodes types" do
      ["true", "false", "1", "1+2"].each do |node|
        context node do
          let(:ruby_code) {
            <<-RUBY
          if #{node}
            wow #{node}
          end
            RUBY
          }

          it do
            expect(nodes.count).to eq(2)
            VisualizeRuby::Graphviz.new(graph).to_graph(png: "spec/examples/node_#{node}.png")
          end
        end
      end
    end
  end

  context "variable assignment" do
    let(:ruby_code) {
      <<-RUBY
      @name = name
      RUBY
    }

    it "converts to nodes and edges" do
      expect(nodes.map(&:to_a)).to eq([[:action, "@name = name"]])
      expect(edges.map(&:to_a)).to eq([])
    end

    it { VisualizeRuby::Graphviz.new(graph).to_graph(png: "spec/examples/variable_assignment.png") }

    context "before an if statement" do
      let(:ruby_code) {
        <<-RUBY
        @name = "Dustin"
        if @name == "Jack"
          jump
        elsif @name == "Dustin"
          hike
        else
          walk  
        end
        RUBY
      }

      it "converts to nodes and edges" do
        expect(nodes.map(&:to_a)).to eq([
                                            [:action, "@name = \"Dustin\""],
                                            [:decision, "@name == \"Jack\""],
                                            [:action, "jump"],
                                            [:decision, "@name == \"Dustin\""],
                                            [:action, "hike"],
                                            [:action, "walk"],
                                        ])
        expect(edges.map(&:to_a)).to eq([
                                                     ["@name = \"Dustin\"", "->", "@name == \"Jack\""],
                                                     ["@name == \"Jack\"", "true", "->", "jump"],
                                                     ["@name == \"Jack\"", "false", "->", "@name == \"Dustin\""],
                                                     ["@name == \"Dustin\"", "true", "->", "hike"],
                                                     ["@name == \"Dustin\"", "false", "->", "walk"],
                                                 ])
      end

      it { VisualizeRuby::Graphviz.new(graph).to_graph(png: "spec/examples/variable_assignment_and_if.png") }
    end
  end
end
