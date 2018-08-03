RSpec.describe VisualizeRuby::Parser do
  subject {
    described_class.new(ruby_code).parse
  }
  let(:graph) {
    instance_double(VisualizeRuby::Graph, nodes: nodes, edges: edges, name: "something", options: {})
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

    it { VisualizeRuby::Graphviz.new(graphs: [graph]).to_graph(path: "spec/examples/link_actions.png") }
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

      it { VisualizeRuby::Graphviz.new(graphs: [graph]).to_graph(path: "spec/examples/or.png") }
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

      it { VisualizeRuby::Graphviz.new(graphs: [graph]).to_graph(path: "spec/examples/and.png") }
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

    it { VisualizeRuby::Graphviz.new(graphs: [graph]).to_graph(path: "spec/examples/if_statement.png") }

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
                                            ["alone?", "true", "->", "eat"],
                                            ["alone?", "false", "->", "sleep"]
                                        ])
      end

      it { VisualizeRuby::Graphviz.new(graphs: [graph]).to_graph(path: "spec/examples/if_with_condition.png") }
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

      it { VisualizeRuby::Graphviz.new(graphs: [graph]).to_graph(path: "spec/examples/elsif.png") }

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

        it { VisualizeRuby::Graphviz.new(graphs: [graph], unique_nodes: false).to_graph(path: "spec/examples/complex_logic.png") }
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
                                              [:action, "clean(:kitchen)"],
                                              [:branch_leaf, "END"]
                                          ])
          expect(edges.map(&:to_a)).to eq([
                                              ["project.done?", "true", "->", "eat(:donuts)"],
                                              ["project.done?", "false", "->", "END"],
                                              ["eat(:donuts)", "->", "clean(:kitchen)"]
                                          ])
        end

        it { VisualizeRuby::Graphviz.new(graphs: [graph]).to_graph(path: "spec/examples/if_with_linked_actions.png") }
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
            expect(nodes.count).to eq(3)
            VisualizeRuby::Graphviz.new(graphs: [graph]).to_graph(path: "spec/examples/node_#{node}.png")
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

    it { VisualizeRuby::Graphviz.new(graphs: [graph]).to_graph(path: "spec/examples/variable_assignment.png") }

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

      it { VisualizeRuby::Graphviz.new(graphs: [graph]).to_graph(path: "spec/examples/variable_assignment_and_if.png") }
    end
  end

  context "case statement" do
    let(:ruby_code) {
      <<-RUBY
        case @name
        when "Tom"
          run
        when "Sam"
          hop
          flop
        else
          swim
        end
      RUBY
    }

    it "converts to nodes and edges" do
      expect(nodes.map(&:to_a)).to eq([
                                          [:decision, "@name"],
                                          [:action, "run"],
                                          [:action, "hop"],
                                          [:action, "flop"],
                                          [:action, "swim"]
                                      ])
      expect(edges.map(&:to_a)).to eq([
                                          ["@name", "\"Tom\"", "->", "run"],
                                          ["@name", "\"Sam\"", "->", "hop"],
                                          ["hop", "->", "flop"],
                                          ["@name", "else", "->", "swim"]
                                      ])
    end

    it { VisualizeRuby::Graphviz.new(graphs: [graph]).to_graph(path: "spec/examples/case_statement.png") }
  end

  context "array" do
    let(:ruby_code) {
      <<-RUBY
      [1,2,3,4,5]
      RUBY
    }

    it "converts to nodes and edges" do
      expect(nodes.map(&:to_a)).to eq([[:action, "[1, 2, 3, 4, 5]"]])
    end
  end

  context "hash" do
    let(:ruby_code) {
      <<-RUBY
      {key: :value}
      RUBY
    }

    it "converts to nodes and edges" do
      expect(nodes.map(&:to_a)).to eq([[:action, "{ key: :value }"]])
    end
  end

  context "and" do
    let(:ruby_code) {
      <<-RUBY
      @name != "Aged Brie" and @name != "Backstage passes to a TAFKAL80ETC concert"
      RUBY
    }

    it "converts to nodes and edges" do
      expect(nodes.map(&:to_a)).to eq([[:decision, "@name != \"Aged Brie\""], [:decision, "@name != \"Backstage passes to a TAFKAL80ETC concert\""]])
      expect(edges.map(&:to_a)).to eq([["@name != \"Aged Brie\"", "AND", "->", "@name != \"Backstage passes to a TAFKAL80ETC concert\""]])
    end
  end

  context "if and else" do
    let(:ruby_code) {
      <<-RUBY
      if 1 == 1 && 2!=3
        run
      else
        walk
      end
      RUBY
    }

    it "converts to nodes and edges" do
      expect(nodes.map(&:to_a)).to eq([[:decision, "1 == 1"], [:decision, "2 != 3"], [:action, "run"], [:action, "walk"]])
      expect(edges.map(&:to_a)).to eq([["1 == 1", "AND", "->", "2 != 3"], ["2 != 3", "true", "->", "run"], ["2 != 3", "false", "->", "walk"]])
    end
  end

  context "one if after another" do
    let(:ruby_code) {
      <<-RUBY
      if 1 == 1
        talk
        if time == now
          run
        end
      else
        walk
      end
      if time > now
        if 1 == 1
         jump
        end
      end
      RUBY
    }

    it "converts to nodes and edges" do
      expect(edges.map(&:to_a)).to eq([["walk", "->", "time > now"], ["run", "->", "time > now"], ["1 == 1", "true", "->", "talk"], ["1 == 1", "false", "->", "walk"], ["talk", "->", "time == now"], ["time == now", "true", "->", "run"], ["time == now", "false", "->", "time > now"], ["time > now", "true", "->", "1 == 1"], ["time > now", "false", "->", "END"], ["1 == 1", "true", "->", "jump"], ["1 == 1", "false", "->", "END"]])
      expect(nodes.map(&:to_a)).to eq([[:decision, "1 == 1"], [:action, "talk"], [:decision, "time == now"], [:action, "run"], [:action, "walk"], [:decision, "time > now"], [:decision, "1 == 1"], [:action, "jump"], [:branch_leaf, "END"], [:branch_leaf, "END"]])
    end

    it { VisualizeRuby::Graphviz.new(graphs: [graph]).to_graph(path: "spec/examples/one if after another.png") }
  end

  context "3 conditions" do
    let(:ruby_code) {
      <<-RUBY
        true || false || :hello
      RUBY
    }

    it "converts to nodes and edges" do
      expect(nodes.map(&:to_a)).to eq([[:decision, "true"], [:decision, "false"], [:decision, ":hello"]])
      expect(edges.map(&:to_a)).to eq([["true", "OR", "->", "false"], ["false", "OR", "->", ":hello"]])
    end

    it { VisualizeRuby::Graphviz.new(graphs: [graph]).to_graph(path: "spec/examples/3_conditions.png") }
    it do
      expect(VisualizeRuby::Graphviz.new(graphs: [graph]).to_graph(format: String)).to eq(<<-RUBY)
digraph G {
	label="something";
	subgraph "cluster_0" {
		label="something";
		style=invis;
		true[shape=diamond, style=rounded, label="true"];
		false[shape=diamond, style=rounded, label="false"];
		":hello L1"[shape=diamond, style=rounded, label=":hello"];
		true -> false[label="OR", dir=forward];
		false -> ":hello L1"[label="OR", dir=forward];
	}
}
      RUBY
    end
  end
end
