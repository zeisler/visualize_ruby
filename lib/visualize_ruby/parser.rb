require "parser/current"
require_relative "parser/conditions"
require_relative "parser/base"
require_relative "parser/or"
require_relative "parser/and"
require_relative "parser/begin"
require_relative "parser/send"
require_relative "parser/str"
require_relative "parser/if"
require_relative "parser/type"
require_relative "parser/true"
require_relative "parser/false"
require_relative "parser/case"
require_relative "parser/block"

module VisualizeRuby
  class Parser
    attr_reader :ast

    def initialize(ruby_code = nil, ast: ::Parser::CurrentRuby.parse(ruby_code))
      @ast = ast
    end

    # @return [Array<VisualizeRuby::Node>, Array<VisualizeRuby::Edge>]
    def parse
      merge *parse_by_type

      return nodes, edges
    end
    
    def nodes
      @nodes ||= []
    end

    def edges
      @edges ||= []
    end

    private

    def parse_by_type
      Parser.const_get(ast.type.to_s.capitalize, false).new(ast).parse
    rescue NameError
      Str.new(ast).parse
    end

    def merge(nodes, edges)
      self.nodes.concat(nodes)
      self.edges.concat(edges)
    end
  end
end
