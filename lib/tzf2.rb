# frozen_string_literal: true

require_relative "tzf2/version"
require_relative "tzf2/errors"
require_relative "tzf2/coordinates"

ruby_minor_version = RUBY_VERSION.split(".")[0..1].join(".")
versioned = File.join(__dir__, "tzf2", ruby_minor_version, "tzf2")
if File.exist?("#{versioned}.bundle") || File.exist?("#{versioned}.so")
  require versioned
else
  require_relative "tzf2/tzf2"
end

module TZF
  class << self
    def tz_name(latitude, longitude)
      coords = Coordinates.parse(latitude, longitude)
      name = raw_tz_name(coords.latitude, coords.longitude)
      raise uncovered_error(coords) if name.empty?

      name
    end

    def tz_names(latitude, longitude)
      coords = Coordinates.parse(latitude, longitude)
      names = raw_tz_names(coords.latitude, coords.longitude)
      raise uncovered_error(coords) if names.empty?

      names
    end

    def data_version
      raw_data_version
    end

    def engine_version
      raw_engine_version
    end

    def timezone_names
      raw_timezone_names
    end

    private

    def uncovered_error(coords)
      UncoveredCoordinateError.new(
        "no timezone covers latitude #{coords.latitude}, longitude #{coords.longitude}"
      )
    end
  end
end
