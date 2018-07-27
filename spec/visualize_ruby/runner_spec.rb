RSpec.describe VisualizeRuby::Runner do
  ruby_code = <<~RUBY
  class Worker
    def initialize(hungry:)
      @hungry = hungry
    end

    def next_action
      if hungry?
        :eat
      else
        :work
      end
    end

    def hungry?
      @hungry
    end
  end
  RUBY

  calling_code = <<~RUBY
  Worker.new(hungry: true).next_action
  RUBY

  it "create a traced graph file" do
    VisualizeRuby.new do |vb|
      vb.ruby_code = ruby_code # String, File, Pathname
      vb.trace(calling_code)  # String, File, Proc
      vb.output_path = "spec/examples/runner_trace.png" # file name with media extension.
      # vb.output_format = String
      # puts vb.run!
    end
  end

  it "trace takes a block" do
    VisualizeRuby.new do |vb|
      vb.ruby_code = ruby_code # String, File, Pathname
      vb.trace do
        Worker.new(hungry: true).next_action
      end
      vb.output_format = String
      expect(vb.run!).to_not eq(nil)
    end
  end

  it "calling output takes a pathname" do
    VisualizeRuby.new do |vb|
      vb.ruby_code = Pathname("spec/examples/gilded_rose.rb")
      vb.calling_code = Pathname("spec/examples/gilded_rose.rb")
      vb.output_format = String
      expect(vb.run!).to_not eq(nil)
    end
  end
end
