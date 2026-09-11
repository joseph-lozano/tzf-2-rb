# frozen_string_literal: true

module TZF
  class Error < StandardError; end

  class InvalidCoordinatesError < Error; end

  class UncoveredCoordinateError < Error; end
end
