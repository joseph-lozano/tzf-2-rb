# frozen_string_literal: true

require_relative "lib/tzf2/version"

Gem::Specification.new do |spec|
  spec.name = "tzf2"
  spec.version = TZF::VERSION
  spec.authors = ["Joseph Lozano"]
  spec.email = ["me@lozanojoseph.com"]

  spec.summary = "Offline latitude/longitude to IANA timezone lookup via tzf-rs 2"
  spec.description = <<~DESC
    Ruby wrapper around tzf-rs v2 for offline timezone lookup from WGS84
    coordinates. Embeds current ocean-inclusive timezone-boundary-builder data
    from tzf-dist. No runtime network access.
  DESC
  spec.homepage = "https://github.com/joseph-lozano/tzf-2-rb"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"
  spec.required_rubygems_version = ">= 3.4.6"

  spec.metadata["bug_tracker_uri"] = "#{spec.homepage}/issues"
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["allowed_push_host"] = "do-not-publish.invalid"

  spec.files = %w[
    CHANGELOG.md
    Cargo.lock
    Cargo.toml
    LICENSE
    LICENSE_DATA
    NOTICE
    README.md
    ext/tzf2/Cargo.toml
    ext/tzf2/extconf.rb
    ext/tzf2/src/lib.rs
    lib/tzf.rb
    lib/tzf2.rb
    lib/tzf2/coordinates.rb
    lib/tzf2/errors.rb
    lib/tzf2/version.rb
    sig/tzf.rbs
    tzf2.gemspec
  ]
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/tzf2/extconf.rb"]

  spec.add_dependency "rb_sys", "~> 0.9.117"
end
