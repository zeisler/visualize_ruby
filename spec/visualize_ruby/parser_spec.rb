RSpec.describe VisualizeRuby::Parser do
  subject {
    described_class.new(ruby_code).parse
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
      expect(nodes.map(&:to_a)).to eq([[:action, :eat_breakfast], [:action, :brush_teeth], [:action, :drive_work]])
      expect(edges.map(&:to_a)).to eq([[:eat_breakfast, "->", :brush_teeth], [:brush_teeth, "->", :drive_work]])
    end

    it "returns [Array[VisualizeRuby::Node], Array[VisualizeRuby::Edge]" do
      expect(subject.flatten.map(&:class).uniq).to eq([VisualizeRuby::Node, VisualizeRuby::Edge])
    end

    it { VisualizeRuby::Graphviz.new(nodes, edges).to_graph(png: "spec/examples/link_actions.png") }
  end

  context "condition" do
    context "OR" do
      let(:ruby_code) {
        <<-RUBY
      person.hungry? || starving?
        RUBY
      }

      it "converts to nodes and edges" do
        expect(nodes.map(&:to_sym)).to eq([:person_hungry?, :starving?])
        expect(edges.map(&:to_a)).to eq([[:person_hungry?, "OR", "->", :starving?]])
      end

      it { VisualizeRuby::Graphviz.new(nodes, edges).to_graph(png: "spec/examples/or.png") }
    end

    context "AND" do
      let(:ruby_code) {
        <<-RUBY
      hungry? && starving?
        RUBY
      }

      it "converts to nodes and edges" do
        expect(nodes.map(&:to_a)).to eq([[:decision, :hungry?], [:decision, :starving?]])
        expect(edges.map(&:to_a)).to eq([[:hungry?, "AND", "->", :starving?]])
      end

      it { VisualizeRuby::Graphviz.new(nodes, edges).to_graph(png: "spec/examples/and.png") }
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
      expect(nodes.map(&:to_sym)).to eq([:hungry?, :eat, :sleep])
      expect(edges.map(&:to_a)).to eq([[:hungry?, "true", "->", :eat], [:hungry?, "false", "->", :sleep]])
    end

    it { VisualizeRuby::Graphviz.new(nodes, edges).to_graph(png: "spec/examples/if_statement.png") }

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
        expect(nodes.map(&:to_sym)).to eq([:hungry?, :alone?, :eat, :sleep])
        expect(edges.map(&:to_a)).to eq([
                                            [:hungry?, "OR", "->", :alone?],
                                            [:hungry?, "true", "->", :eat],
                                            [:hungry?, "false", "->", :sleep],
                                            [:alone?, "true", "->", :eat],
                                            [:alone?, "false", "->", :sleep]
                                        ])
      end

      it { VisualizeRuby::Graphviz.new(nodes, edges).to_graph(png: "spec/examples/if_with_condition.png") }
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
                                            [:decision, :project_done?],
                                            [:action, :go_on_vacation],
                                            [:decision, :project_blocked?],
                                            [:action, :eat_donuts],
                                            [:action, :sleep]
                                        ])
        expect(edges.map(&:to_a)).to eq([
                                            [:project_done?, "true", "->", :go_on_vacation],
                                            [:project_done?, "false", "->", :project_blocked?],
                                            [:project_blocked?, "true", "->", :eat_donuts],
                                            [:project_blocked?, "false", "->", :sleep]
                                        ])
      end

      it { VisualizeRuby::Graphviz.new(nodes, edges).to_graph(png: "spec/examples/elsif.png") }

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

        it { VisualizeRuby::Graphviz.new(nodes, edges).to_graph(png: "spec/examples/complex_logic.png") }
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
                                              [:decision, :project_done?],
                                              [:action, :eat_donuts],
                                              [:action, :clean_kitchen]
                                          ])
          expect(edges.map(&:to_a)).to eq([
                                              [:project_done?, "true", "->", :eat_donuts],
                                           [:eat_donuts, "->", :clean_kitchen]
                                          ])
        end

        it { VisualizeRuby::Graphviz.new(nodes, edges).to_graph(png: "spec/examples/if_with_linked_actions.png") }
      end
    end
  end
end
