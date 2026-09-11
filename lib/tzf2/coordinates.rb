# frozen_string_literal: true

module TZF
  class Coordinates
    attr_reader :latitude, :longitude

    def self.parse(latitude, longitude)
      new(latitude, longitude)
    end

    def initialize(latitude, longitude)
      @latitude = finite_float(latitude, "latitude")
      @longitude = finite_float(longitude, "longitude")
      unless (-90.0..90.0).cover?(@latitude)
        raise InvalidCoordinatesError, "latitude #{@latitude} is outside -90..90"
      end
      unless (-180.0..180.0).cover?(@longitude)
        raise InvalidCoordinatesError, "longitude #{@longitude} is outside -180..180"
      end
    end

    private

    def finite_float(value, name)
      unless value.is_a?(Numeric)
        raise InvalidCoordinatesError, "#{name} must be numeric, got #{value.class}"
      end

      float = Float(value)
      unless float.finite?
        raise InvalidCoordinatesError, "#{name} must be a finite number"
      end

      float
    end
  end
end
