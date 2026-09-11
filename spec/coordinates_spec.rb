# frozen_string_literal: true

RSpec.describe TZF::Coordinates do
  it "accepts integer degrees" do
    coords = described_class.parse(40, -74)
    expect(coords.latitude).to eq(40.0)
    expect(coords.longitude).to eq(-74.0)
  end

  it "accepts the poles and the antimeridian" do
    expect(described_class.parse(90, 180).latitude).to eq(90.0)
    expect(described_class.parse(-90, -180).longitude).to eq(-180.0)
  end

  it "rejects a non-numeric latitude" do
    expect { described_class.parse("40.7", -74.0) }
      .to raise_error(TZF::InvalidCoordinatesError, /latitude must be numeric/)
  end

  it "rejects a non-numeric longitude" do
    expect { described_class.parse(40.7, nil) }
      .to raise_error(TZF::InvalidCoordinatesError, /longitude must be numeric/)
  end

  it "rejects NaN" do
    expect { described_class.parse(Float::NAN, 0) }
      .to raise_error(TZF::InvalidCoordinatesError, /latitude must be a finite number/)
  end

  it "rejects infinity" do
    expect { described_class.parse(0, Float::INFINITY) }
      .to raise_error(TZF::InvalidCoordinatesError, /longitude must be a finite number/)
  end

  it "rejects latitude outside -90..90" do
    expect { described_class.parse(90.0001, 0) }
      .to raise_error(TZF::InvalidCoordinatesError, /latitude 90.0001 is outside -90..90/)
  end

  it "rejects longitude outside -180..180" do
    expect { described_class.parse(0, -180.0001) }
      .to raise_error(TZF::InvalidCoordinatesError, /longitude -180.0001 is outside -180..180/)
  end
end

RSpec.describe TZF do
  describe "coordinate order" do
    it "treats the first argument as latitude" do
      expect(described_class.tz_name(40.7128, -74.0060)).to eq("America/New_York")
    end

    it "does not treat swapped arguments as the same zone" do
      expect(described_class.tz_name(-74.0060, 40.7128)).not_to eq("America/New_York")
    end
  end

  describe "invalid lookup input" do
    it "raises InvalidCoordinatesError for a string latitude" do
      expect { described_class.tz_name("40.7", -74.0) }
        .to raise_error(TZF::InvalidCoordinatesError)
    end

    it "raises InvalidCoordinatesError for an out-of-range longitude" do
      expect { described_class.tz_names(0, 181) }
        .to raise_error(TZF::InvalidCoordinatesError)
    end

    it "raises UncoveredCoordinateError when the engine returns no zone" do
      allow(described_class).to receive(:raw_tz_name).and_return("")
      expect { described_class.tz_name(0, 0) }
        .to raise_error(TZF::UncoveredCoordinateError, /no timezone covers latitude 0.0, longitude 0.0/)
    end
  end
end
