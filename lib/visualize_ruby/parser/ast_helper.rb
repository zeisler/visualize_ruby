module VisualizeRuby
  class Parser
    class AstHelper
      def initialize(ast)
        @ast = ast
      end

      def description(ast: @ast)
        case ast
        when Symbol, String
          ast
        when NilClass
          nil

        else
          ast.children.flat_map do |c|
            description(ast: c)
          end.reject do |c|
            c.nil? || c == :""
          end.join(" ")
        end
      rescue NoMethodError
        ast
      end
    end
  end
end
