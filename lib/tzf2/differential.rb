# frozen_string_literal: true

require "json"
require "yaml"

module TZF
  class Differential
    INSTANT = Time.utc(2026, 1, 15, 12, 0, 0)
    GRID_STEP = 10
    BASELINE_PATH = File.expand_path("../../spec/fixtures/differential_baseline.json", __dir__)
    LOCATIONS_PATH = File.expand_path("../../spec/fixtures/locations.yml", __dir__)

    Sample = Struct.new(:id, :lat, :lng, :tz_name, :tz_names, :utc_offset, :covered, keyword_init: true)

    def self.catalog
      named + grid
    end

    def self.named
      YAML.load_file(LOCATIONS_PATH).fetch("locations").map do |name, point|
        sample("named:#{name}", point.fetch("lat"), point.fetch("lng"))
      end
    end

    def self.grid
      (-90..90).step(GRID_STEP).flat_map do |lat|
        (-180..180).step(GRID_STEP).map do |lng|
          sample("grid:#{lat},#{lng}", lat.to_f, lng.to_f)
        end
      end
    end

    def self.sample(id, lat, lng)
      name = TZF.tz_name(lat, lng)
      names = TZF.tz_names(lat, lng)
      Sample.new(
        id: id,
        lat: lat,
        lng: lng,
        tz_name: name,
        tz_names: names,
        utc_offset: utc_offset(name),
        covered: true
      )
    rescue UncoveredCoordinateError
      Sample.new(
        id: id,
        lat: lat,
        lng: lng,
        tz_name: nil,
        tz_names: [],
        utc_offset: nil,
        covered: false
      )
    end

    def self.utc_offset(tz_name)
      require "tzinfo"
      TZInfo::Timezone.get(tz_name).period_for(INSTANT).utc_total_offset
    rescue LoadError, TZInfo::InvalidTimezoneIdentifier
      nil
    end

    def self.snapshot(samples = catalog)
      {
        "engine_version" => TZF.engine_version,
        "data_version" => TZF.data_version,
        "instant" => INSTANT.strftime("%Y-%m-%dT%H:%M:%SZ"),
        "grid_step" => GRID_STEP,
        "points" => samples.to_h { |sample| [sample.id, sample_hash(sample)] }
      }
    end

    def self.sample_hash(sample)
      {
        "lat" => sample.lat,
        "lng" => sample.lng,
        "tz_name" => sample.tz_name,
        "tz_names" => sample.tz_names,
        "utc_offset" => sample.utc_offset,
        "covered" => sample.covered
      }
    end

    def self.write_baseline(path = BASELINE_PATH)
      File.write(path, "#{JSON.pretty_generate(snapshot)}\n")
      path
    end

    def self.compare(path = BASELINE_PATH)
      baseline = JSON.parse(File.read(path))
      current = snapshot
      Report.new(baseline, current).tap(&:compute)
    end

    class Report
      Change = Struct.new(:id, :kind, :before, :after, keyword_init: true)

      attr_reader :baseline, :current, :changes

      def initialize(baseline, current)
        @baseline = baseline
        @current = current
        @changes = []
      end

      def compute
        old_points = baseline.fetch("points")
        new_points = current.fetch("points")
        (old_points.keys | new_points.keys).sort.each do |id|
          prior = old_points[id]
          now = new_points[id]
          if prior.nil?
            changes << Change.new(id: id, kind: "added_point", before: nil, after: now)
            next
          end
          if now.nil?
            changes << Change.new(id: id, kind: "removed_point", before: prior, after: nil)
            next
          end
          if prior["covered"] && !now["covered"]
            changes << Change.new(id: id, kind: "uncovered", before: prior, after: now)
          elsif !prior["covered"] && now["covered"]
            changes << Change.new(id: id, kind: "newly_covered", before: prior, after: now)
          end
          if prior["tz_name"] != now["tz_name"]
            changes << Change.new(id: id, kind: "timezone_id", before: prior["tz_name"], after: now["tz_name"])
          end
          if prior["utc_offset"] != now["utc_offset"]
            changes << Change.new(id: id, kind: "utc_offset", before: prior["utc_offset"], after: now["utc_offset"])
          end
        end
        self
      end

      def clean?
        changes.empty?
      end

      def grouped
        changes.group_by(&:kind)
      end

      def to_s
        return "no differential changes" if clean?

        grouped.map do |kind, items|
          lines = items.map { |change| "  #{change.id}: #{change.before.inspect} -> #{change.after.inspect}" }
          "#{kind} (#{items.length})\n#{lines.join("\n")}"
        end.join("\n\n")
      end
    end
  end
end
