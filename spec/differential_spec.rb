# frozen_string_literal: true

require_relative "support/differential"

RSpec.describe TZF::Differential do
  it "matches the committed baseline" do
    report = described_class.compare
    expect(report).to be_clean, report.to_s
  end

  it "classifies a timezone-id change" do
    baseline = {
      "points" => {
        "named:example" => {
          "lat" => 40.7,
          "lng" => -74.0,
          "tz_name" => "America/New_York",
          "tz_names" => ["America/New_York"],
          "utc_offset" => -18000,
          "covered" => true
        }
      }
    }
    current = {
      "points" => {
        "named:example" => baseline["points"]["named:example"].merge("tz_name" => "America/Detroit")
      }
    }
    report = described_class::Report.new(baseline, current).tap(&:compute)
    expect(report.changes.map(&:kind)).to eq(["timezone_id"])
  end

  it "classifies a tz_names change when tz_name stays the same" do
    baseline = {
      "points" => {
        "named:overlap" => {
          "lat" => 44.04,
          "lng" => 87.416,
          "tz_name" => "Asia/Shanghai",
          "tz_names" => ["Asia/Shanghai", "Asia/Urumqi"],
          "utc_offset" => 28_800,
          "covered" => true
        }
      }
    }
    current = {
      "points" => {
        "named:overlap" => baseline["points"]["named:overlap"].merge(
          "tz_names" => ["Asia/Shanghai"]
        )
      }
    }
    report = described_class::Report.new(baseline, current).tap(&:compute)
    expect(report.changes.map(&:kind)).to eq(["timezone_names"])
    expect(report.changes.first.before).to eq(["Asia/Shanghai", "Asia/Urumqi"])
    expect(report.changes.first.after).to eq(["Asia/Shanghai"])
  end

  it "classifies newly covered and uncovered points" do
    baseline = {
      "points" => {
        "grid:0,0" => { "tz_name" => nil, "utc_offset" => nil, "covered" => false },
        "grid:10,10" => { "tz_name" => "Africa/Lagos", "utc_offset" => 3600, "covered" => true }
      }
    }
    current = {
      "points" => {
        "grid:0,0" => { "tz_name" => "Etc/GMT", "utc_offset" => 0, "covered" => true },
        "grid:10,10" => { "tz_name" => nil, "utc_offset" => nil, "covered" => false }
      }
    }
    kinds = described_class::Report.new(baseline, current).tap(&:compute).changes.map(&:kind)
    expect(kinds).to include("newly_covered", "uncovered", "timezone_id", "utc_offset")
  end
end
