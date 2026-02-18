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
  spec.add_runtime_dependency "rubocop-ast", "~> 1.40.0"
  spec.add_runtime_dependency "rubocop-performance"
  spec.add_runtime_dependency "rubocop-rails"

  spec.add_runtime_dependency "rexml", ">= 3.4.4"  # rubocop depends on rexml. Enforce a minimum for CVE-2025-58767

  # rubocop-rails depends on rack. Enforce a minimum for various CVEs
  #
  # NOTE: Previously we locked down to exclude many specific versions, but due to
  # https://github.com/rubygems/rubygems.org/issues/5541 we can't release the gem.
  # For now, we just lock down to at least the minimum rack.
  spec.add_runtime_dependency "rack", ">= 2.2.22", "< 4" # CVE-2026-25500 https://github.com/advisories/GHSA-whrj-4476-wvmp

  spec.add_development_dependency "rake",      "~> 12.0"
  spec.add_development_dependency "rspec",     "~> 3.0"
  spec.add_development_dependency "simplecov", ">= 0.21.2"
end
