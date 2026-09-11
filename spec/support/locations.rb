# frozen_string_literal: true

require "yaml"

module SpecLocations
  PATH = File.expand_path("../fixtures/locations.yml", __dir__)

  def self.all
    @all ||= YAML.load_file(PATH).fetch("locations")
  end
end
