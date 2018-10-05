require "active_support/core_ext/time"
require "active_support/core_ext/integer/time"

RSpec.describe VisualizeRuby::Runner do
  ruby_code = <<~RUBY
    class Worker
      def initialize(hungry:)
        @hungry = hungry
      end

      def next_action
        hungry? ? :eat : :work
      end

      def hungry?
        @hungry
      end
    end
  RUBY

  calling_code = <<~RUBY
    Worker.new(hungry: true).next_action
  RUBY

  it "normalize_ruby" do
    VisualizeRuby.new do |vb|
      vb.ruby_code      = ruby_code
      vb.output_format  = String
      vb.normalize_ruby = true
      expect(vb.run!.send(:builder).ruby_code).to include <<~RUBY
      def next_action
        if hungry?
          :eat
        else
          :work
        end
      end
      RUBY
    end
  end

  it "create a traced graph file" do
    VisualizeRuby.new do |vb|
      vb.ruby_code = ruby_code # String, File, Pathname
      vb.trace(calling_code) # String, File, Proc
      vb.output_path = "spec/examples/runner_trace.png" # file name with media extension.
    end
  end

  it "trace takes a block" do
    VisualizeRuby.new do |vb|
      vb.ruby_code = ruby_code # String, File, Pathname
      vb.trace do
        Worker.new(hungry: true).next_action
      end
      vb.output_format = String
      expect(vb.run!.output).to be_an_instance_of(String)
    end
  end

  it "calling output takes a pathname" do
    grapher = VisualizeRuby.new do |vb|
      vb.ruby_code     = Pathname("spec/examples/gilded_rose.rb")
      vb.calling_code  = Pathname("spec/examples/gilded_rose.rb")
      vb.output_format = String
      vb.unique_nodes  = false
    end

    expect(grapher.output).to be_an_instance_of(String)
  end

  it "as passed in options" do
    grapher = VisualizeRuby.new do |vb|
      vb.options(
        ruby_code:     Pathname("spec/examples/gilded_rose.rb"),
        calling_code:  Pathname("spec/examples/gilded_rose.rb"),
        output_format: String,
        unique_nodes:  false,
      )
    end

    expect(grapher.output).to be_an_instance_of(String)
  end

  describe "graphs" do
    it "sends back graph names" do
      grapher = VisualizeRuby.new do |vb|
        vb.options(
          ruby_code:     Pathname("spec/examples/gilded_rose.rb"),
          calling_code:  Pathname("spec/examples/gilded_rose.rb"),
          output_format: String,
          unique_nodes:  false,
        )

        expect(vb.run!).to_not eq(nil)
      end
      expect(grapher.graphs).to eq(%w(GildedRose initialize tick))
    end
  end

  context "bankruptcy rule" do
    let(:vb) { VisualizeRuby.new }

    before do
      vb.ruby_code = Pathname("spec/examples/bankruptcy_rule.rb")
      vb.trace do
        BankruptcyRule.new(
          credit_report: OpenStruct.new(fico: 800),
          bankruptcies:  [OpenStruct.new(closed_date: 2.years.ago)]
        ).eligible?
      end
      vb.in_line_local_method_calls = false
    end

    it "to file" do
      vb.output_path = "spec/examples/bankruptcy_rule.png"
      vb.run!
    end
  end
end
