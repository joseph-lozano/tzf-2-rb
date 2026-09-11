# frozen_string_literal: true

require "support/locations"

RSpec.describe TZF do
  it "reports a gem version" do
    expect(TZF::VERSION).to eq("0.1.0")
  end

  it "reports the tzf-rs engine version" do
    expect(described_class.engine_version).to eq("2.0.0")
  end

  it "keeps engine_version aligned with Cargo.lock" do
    lock = File.read(File.expand_path("../Cargo.lock", __dir__))
    expect(lock).to include("name = \"tzf-rs\"\nversion = \"#{described_class.engine_version}\"")
  end

  it "reports the embedded boundary-data version" do
    expect(described_class.data_version).to eq("2026c")
  end

  it "embeds ocean-inclusive IANA names" do
    names = described_class.timezone_names
    expect(names).to include("America/New_York", "Etc/GMT+8")
    expect(names.length).to eq(444)
  end

  describe ".tz_name" do
    it "returns a land zone" do
      expect(described_class.tz_name(40.7128, -74.0060)).to eq("America/New_York")
    end

    it "returns an open-ocean zone" do
      expect(described_class.tz_name(0.0, 0.0)).to eq("Etc/GMT")
    end

    it "returns a polar zone" do
      expect(described_class.tz_name(-90.0, 0.0)).to eq("Antarctica/McMurdo")
    end

    it "returns an antimeridian zone" do
      expect(described_class.tz_name(0.0, 180.0)).to eq("Etc/GMT-12")
      expect(described_class.tz_name(0.0, -180.0)).to eq("Etc/GMT+12")
    end

    SpecLocations.all.each do |name, point|
      it "returns #{point.fetch('tz_name')} for #{name}" do
        expect(described_class.tz_name(point.fetch("lat"), point.fetch("lng")))
          .to eq(point.fetch("tz_name"))
      end
    end
  end

  describe ".tz_names" do
    it "returns every match on a shared border, sorted" do
      expect(described_class.tz_names(44.04, 87.416))
        .to eq(["Asia/Shanghai", "Asia/Urumqi"])
    end

    SpecLocations.all.each do |name, point|
      it "returns #{point.fetch('tz_names').inspect} for #{name}" do
        expect(described_class.tz_names(point.fetch("lat"), point.fetch("lng")))
          .to eq(point.fetch("tz_names"))
      end
    end
  end
end
