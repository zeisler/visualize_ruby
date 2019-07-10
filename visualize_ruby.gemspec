lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "visualize_ruby/version"

Gem::Specification.new do |spec|
  spec.name          = "visualize_ruby"
  spec.version       = VisualizeRuby::VERSION
  spec.authors       = ["Dustin Zeisler"]
  spec.email         = ["dustin@zeisler.net"]

  spec.summary       = %q{Express logic visually with the code you already know, Ruby.}
  spec.description   = %q{Turn Ruby code into flow charts}
  spec.homepage      = "https://github.com/zeisler/visualize_ruby"
  spec.license       = "MIT"

  spec.files         = Dir.chdir(File.expand_path("..", __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.3"

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake",  "~> 12.3", ">= 12.3.1"
  spec.add_development_dependency "rspec", "~> 3.7"
  spec.add_development_dependency "activesupport", "~> 5.2"

  spec.add_runtime_dependency "graphviz", "~> 1.0"
  spec.add_runtime_dependency "dissociated_introspection", "~> 0.12.0"
  spec.add_runtime_dependency "parser", ">= 2.3"
end
