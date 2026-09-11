# frozen_string_literal: true

require "json"
require "open3"

RSpec.describe "Ruby and Rust grid parity" do
  BIN = File.expand_path("../target/release/grid_parity", __dir__)
  MANIFEST = File.expand_path("../crates/grid_parity/Cargo.toml", __dir__)
  TARGET = File.expand_path("../target", __dir__)

  it "returns the same zone as tzf-rs on a 10-degree grid" do
    compare_grid(10)
  end

  it "returns the same zone as tzf-rs on a 0.1-degree grid" do
    compare_grid(0.1, ndjson: true)
  end

  def compare_grid(step, ndjson: false)
    build_bin!
    counted = 0
    mismatches = []
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    command = ndjson ? [BIN, step.to_s, "--ndjson"] : [BIN, step.to_s]

    Open3.popen3(*command) do |stdin, stdout, stderr, wait_thr|
      stdin.close
      if ndjson
        stdout.each_line do |line|
          counted += 1
          record_mismatch(mismatches, JSON.parse(line))
        end
      else
        JSON.parse(stdout.read).each do |point|
          counted += 1
          record_mismatch(mismatches, point)
        end
      end
      status = wait_thr.value
      raise "grid_parity failed: #{stderr.read}" unless status.success?
    end

    elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started
    warn format(
      "grid parity step=%s: %.3fs, %d points, %d mismatches",
      step, elapsed, counted, mismatches.length
    )

    expect(counted).to eq(grid_size(step))
    expect(mismatches).to eq([])
  end

  def record_mismatch(mismatches, point)
    lat = point.fetch("lat")
    lng = point.fetch("lng")
    name = TZF.raw_tz_name(lat, lng)
    names = TZF.raw_tz_names(lat, lng)
    return if name == point.fetch("tz_name") && names == point.fetch("tz_names")

    mismatches << {
      "lat" => lat,
      "lng" => lng,
      "ruby_tz_name" => name,
      "rust_tz_name" => point.fetch("tz_name"),
      "ruby_tz_names" => names,
      "rust_tz_names" => point.fetch("tz_names")
    }
  end

  def build_bin!
    return if File.executable?(BIN)

    ok = system(
      { "CARGO_TARGET_DIR" => TARGET },
      "cargo", "build", "--quiet", "--release", "--manifest-path", MANIFEST, "--bin", "grid_parity"
    )
    raise "cargo build --bin grid_parity failed" unless ok
  end

  def grid_size(step)
    step_md = (step * 1000).round
    ((((90 - -90) * 1000) / step_md) + 1) * ((((180 - -180) * 1000) / step_md) + 1)
  end
end
