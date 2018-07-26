require "visualize_ruby/version"
require "visualize_ruby/parser"
require "visualize_ruby/optionalable"
require "visualize_ruby/touchable"
require "visualize_ruby/node"
require "visualize_ruby/edge"
require "visualize_ruby/graph"
require "visualize_ruby/builder"
require "visualize_ruby/graphviz"
require "visualize_ruby/ast_helper"
require "visualize_ruby/runner"
require "visualize_ruby/execution_tracer"
require "visualize_ruby/highlight_tracer"

module VisualizeRuby
  def self.new
    runner = Runner.new
    if block_given?
      yield(runner)
      runner.run!
    else
      runner
    end
  end
end
