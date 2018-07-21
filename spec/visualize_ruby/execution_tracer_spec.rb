require "visualize_ruby/execution_tracer"

RSpec.describe VisualizeRuby::ExecutionTracer do
  describe "#trace" do
    subject {
      described_class.new(ruby_code: ruby_code, calling_code: calling_code)
    }

    context "simple" do
      let(:ruby_code) { <<~RUBY
        class World
          def testing(color)
            if color == :red
              paint_town!
            else
              "not red"
            end
          end

          def paint_town!
            "hello"
          end
        end
      RUBY
      }

      context "red path" do
        let(:calling_code) { <<~RUBY
          World.new.testing(:red)
        RUBY
        }

        it do
          subject.trace
          expect(subject.executed_lines).to eq([2, 3, 4, 10, 11, 12, 8])
        end
      end

      context "other path" do
        let(:calling_code) { <<~RUBY
          World.new.testing(:blue)
        RUBY
        }

        it do
          subject.trace
          expect(subject.executed_lines).to eq([2, 3, 6, 8])
        end
      end
    end

    context "gilded rose" do
      let(:ruby_code) { File.read(File.join(File.dirname(__FILE__), "../examples/gilded_rose.rb")) }

      let(:calling_code) { <<~RUBY
        GildedRose.new(name: "testing", days_remaining: 10, quality: 50).tick
      RUBY
      }

      it do
        subject.trace
        expect(subject.executed_lines).to eq([4, 5, 6, 7, 8, 10, 11, 12, 13, 14, 34, 35, 37, 54])
      end
    end
  end
end
