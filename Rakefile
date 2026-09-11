# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rb_sys/extensiontask"

GEMSPEC = Gem::Specification.load("tzf2.gemspec")

RbSys::ExtensionTask.new("tzf2", GEMSPEC) do |ext|
  ext.lib_dir = "lib/tzf2"
  ext.cross_compile = true
  ext.cross_platform = %w[
    x86_64-linux
    aarch64-linux
    x86_64-darwin
    arm64-darwin
  ]
end

desc "Build the standalone tzf-rs grid walker"
task :grid_parity_bin do
  target = File.expand_path("target", __dir__)
  sh "env", "CARGO_TARGET_DIR=#{target}",
     "cargo", "build", "--quiet", "--release",
     "--manifest-path", "crates/grid_parity/Cargo.toml",
     "--bin", "grid_parity"
end

RSpec::Core::RakeTask.new(:spec)
task spec: %i[compile grid_parity_bin]

desc "Compare the current lookup table to the committed differential baseline"
task differential: :compile do
  ruby "bin/differential"
end

desc "Write a fresh differential baseline from the current engine"
task "differential:write": :compile do
  ruby "bin/differential", "--write"
end

task default: %i[compile spec]
