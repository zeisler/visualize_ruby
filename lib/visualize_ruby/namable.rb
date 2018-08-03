module VisualizeRuby
  module Namable
    DEFAULT_DISPLAYER = -> (attr) do
      r = attr.values.compact.join(" ")
      r.empty? ? nil : r
    end

    def post_initialize(name_displayer: nil, **args)
      @name_displayer = name_displayer || DEFAULT_DISPLAYER
      super if defined? super
    end

    def name
      @name_displayer.call(build_name_list)
    end

    def self.included(klass)
      klass.extend(ClassMethods)
    end

    module ClassMethods
      def add_names(*names)
        @name_registry = name_registry.concat(names).uniq
      end

      def name_registry
        @name_registry ||= []
      end
    end

    private

    def build_name_list
      self.class.name_registry.each_with_object({}) { |meth, hash| hash[meth] = __send__(meth) }
    end
  end
end
