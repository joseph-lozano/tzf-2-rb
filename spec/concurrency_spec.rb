# frozen_string_literal: true

RSpec.describe "concurrent lookups" do
  it "returns the same zone from many threads" do
    results = Array.new(32) do
      Thread.new { TZF.tz_name(40.7128, -74.0060) }
    end.map(&:value)

    expect(results.uniq).to eq(["America/New_York"])
  end

  it "keeps land and ocean answers stable under mixed concurrent load" do
    points = [
      [40.7128, -74.0060, "America/New_York"],
      [-48.876667, -123.393333, "Etc/GMT+8"],
      [0.0, 0.0, "Etc/GMT"],
      [0.0, 180.0, "Etc/GMT-12"]
    ]

    results = 40.times.flat_map do
      points.map do |lat, lng, expected|
        Thread.new { [expected, TZF.tz_name(lat, lng), TZF.tz_names(lat, lng)] }
      end
    end.map(&:value)

    results.each do |expected, name, names|
      expect(name).to eq(expected)
      expect(names).to include(expected)
    end
  end
end
