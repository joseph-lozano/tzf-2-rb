# frozen_string_literal: true

require "json"
require "open3"
require_relative "../lib/tzf2/differential"

RSpec.describe "Ruby and Rust grid parity" do
  BIN = File.expand_path("../target/release/grid_parity", __dir__)
  STEP = TZF::Differential::GRID_STEP

  it "returns the same zone as tzf-rs on a 10-degree grid" do
    rust_points = rust_grid(STEP)
    expect(rust_points.length).to eq(grid_size(STEP))

    rust_points.each do |point|
      lat = point.fetch("lat")
      lng = point.fetch("lng")
      expect(TZF.raw_tz_name(lat, lng)).to eq(point.fetch("tz_name")),
                                           "tz_name mismatch at #{lat}, #{lng}"
      expect(TZF.raw_tz_names(lat, lng)).to eq(point.fetch("tz_names")),
                                            "tz_names mismatch at #{lat}, #{lng}"
    end
  end

  def rust_grid(step)
    build_bin!
    stdout, stderr, status = Open3.capture3(BIN, step.to_s)
    raise "grid_parity failed: #{stderr}" unless status.success?

    JSON.parse(stdout)
  end

  def build_bin!
    return if File.executable?(BIN)

    ok = system("cargo", "build", "--quiet", "--release", "--bin", "grid_parity")
    raise "cargo build --bin grid_parity failed" unless ok
  end

  def grid_size(step)
    (((90 - -90) / step) + 1) * (((180 - -180) / step) + 1)
  end
end
