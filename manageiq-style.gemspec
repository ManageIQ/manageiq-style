require_relative 'lib/manageiq/style/version'

Gem::Specification.new do |spec|
  spec.name          = "manageiq-style"
  spec.version       = ManageIQ::Style::VERSION
  spec.authors       = ["ManageIQ Authors"]

  spec.summary       = "Style and linting configuration for ManageIQ projects."
  spec.description   = spec.summary
  spec.homepage      = "https://github.com/ManageIQ/manageiq-style"
  spec.license       = "MIT"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["source_code_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "more_core_extensions"
  spec.add_runtime_dependency "optimist"
  spec.add_runtime_dependency "rubocop", "= 1.56.3"
  spec.add_runtime_dependency "rubocop-performance"
  spec.add_runtime_dependency "rubocop-rails"

  spec.add_runtime_dependency "rexml", ">= 3.3.9"  # rubocop depends on rexml. Enforce a minimum for CVE-2024-49761

  # rubocop-rails depends on rack. Enforce a minimum of 2.2.13, 3.0.14, or 3.1.12 for CVE-2025-27610
  spec.add_runtime_dependency "rack", ">= 2.2.13", *("!= 3.0.0".."!= 3.0.9"), "!= 3.0.4.1", "!= 3.0.4.2", "!= 3.0.6.1", "!= 3.0.9.1", *("!= 3.0.10".."!= 3.0.13"), *("!= 3.1.0".."!= 3.1.9"), *("!= 3.1.10".."!= 3.1.11"), "< 4"

  spec.add_development_dependency "rake",      "~> 12.0"
  spec.add_development_dependency "rspec",     "~> 3.0"
  spec.add_development_dependency "simplecov", ">= 0.21.2"
end
