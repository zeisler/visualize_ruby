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

  # Prism's Parser translation keeps the AST API used by this gem while
  # accepting current Ruby syntax (including Ruby 4.0).
  spec.required_ruby_version = ">= 3.1"

  spec.add_development_dependency "rake", "~> 13.2"
  spec.add_development_dependency "rspec", "~> 3.13"
  spec.add_development_dependency "activesupport", "~> 7.2"
  spec.add_development_dependency "ostruct", ">= 0.5", "< 1.0"

  spec.add_runtime_dependency "graphviz", "~> 1.2"
  spec.add_runtime_dependency "parser", ">= 3.3", "< 4.0"
  spec.add_runtime_dependency "prism", ">= 1.6", "< 2.0"
  spec.add_runtime_dependency "unparser", ">= 0.8", "< 1.0"
end
