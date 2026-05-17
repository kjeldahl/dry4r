# frozen_string_literal: true

require_relative "lib/dry4r/version"

Gem::Specification.new do |spec|
  spec.name        = "dry4r"
  spec.version     = Dry4r::VERSION
  spec.authors     = ["Jacob Kjeldahl"]
  spec.summary     = "Finds candidate duplicate Ruby code across files and directories."
  spec.description = <<~DESC
    dry4r reports fuzzy structural matches between Ruby methods. Each method is
    normalized into a syntax-tree fingerprint set; Jaccard similarity over those
    sets identifies candidates worth review.
  DESC
  spec.license     = "MIT"
  spec.homepage    = "https://github.com/kjeldahl/dry4r"

  spec.required_ruby_version = ">= 3.0.0"

  spec.files = Dir["lib/**/*.rb", "exe/*", "README.md", "LICENSE"]
  spec.bindir = "exe"
  spec.executables = ["dry4r"]
  spec.require_paths = ["lib"]

  spec.add_dependency "prism", ">= 0.19"

  spec.metadata = {
    "source_code_uri" => "https://github.com/kjeldahl/dry4r",
    "rubygems_mfa_required" => "true"
  }
end
