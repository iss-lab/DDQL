lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ddql/version"

Gem::Specification.new do |spec|
  spec.name          = "ddql"
  spec.version       = DDQL::VERSION
  spec.authors       = ["Jason Rogers"]
  spec.email         = ["jacaetevha@gmail.com"]

  spec.summary       = %q{DataDesk Query Language parser for Ruby}
  spec.homepage      = "https://github.com/iss-lab/DDQL"
  spec.license       = "MIT"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/iss-lab/DDQL"
  spec.metadata["changelog_uri"] = "https://github.com/iss-lab/DDQL/blob/master/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "parslet", "~> 2.0"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  unless RUBY_PLATFORM == 'java'
    spec.add_development_dependency "pry-byebug", "~> 3.9"
  end
end
