module VisualizeRuby
  class AstHelper
    def initialize(ast)
      @ast = ast
    end

    def description
      return @ast unless @ast.respond_to?(:type)
      Unparser.unparse(@ast)
    end

    def id(description: self.description)
      description.to_s + " L#{[@ast.location.first_line, @ast.location.last_line].compact.uniq.join("-")}"
    end
  end
end
