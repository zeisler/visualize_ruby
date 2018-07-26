module VisualizeRuby
  module Optionalable
    def post_initialize(**opts)
      @graph_viz_options = opts
      super if defined? super
    end

    def options(args={})
      @graph_viz_options.merge!(args)
      @graph_viz_options
    end

    attr_reader :graph_viz_options
  end
end
