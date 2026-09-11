# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rb_sys/extensiontask"

GEMSPEC = Gem::Specification.load("tzf2.gemspec")

RbSys::ExtensionTask.new("tzf2", GEMSPEC) do |ext|
  ext.lib_dir = "lib/tzf2"
  ext.cross_platform = %w[
    x86_64-linux
    aarch64-linux
    x86_64-darwin
    arm64-darwin
  ]
end

desc "Build the standalone tzf-rs grid walker"
task :grid_parity_bin do
  sh "cargo", "build", "--quiet", "--release", "--bin", "grid_parity"
end

RSpec::Core::RakeTask.new(:spec)
task spec: %i[compile grid_parity_bin]

desc "Compare the current lookup table to the committed differential baseline"
task differential: :compile do
  ruby "bin/differential"
end

desc "Print init time, query time, RSS, and package size"
task measure: :compile do
  ruby "bin/measure"
end

desc "Write a fresh differential baseline from the current engine"
task "differential:write": :compile do
  ruby "bin/differential", "--write"
end

task default: %i[compile spec]
