require "net/http"
require "json"
require "active_support/core_ext/time"

require_relative "../base_client"

module Divvy
  class Client
    include BaseClient
    include Timezone::Chicago

    attr_reader :stations

    def initialize(watch_stations: [])
      @watch_stations = watch_stations.map(&:to_i)

      @success = false
      @error_message = nil
      @stations = []
      @updated_at = nil
    end

    def fetch
      response = http.request(Net::HTTP::Get.new("/stations/stations.json"))

      unless response.code == "200"
        return error("Could not fetch stations from Divvy (HTTP #{response.code})")
      end

      parsed_response = JSON.parse(response.body)
      all_stations = parsed_response.fetch("stationBeanList", [])

      log "Got status for #{all_stations.length} stations"

      @stations = all_stations.select { |station| @watch_stations.include?(station["id"]) }
      @updated_at = timezone.parse(parsed_response["executionTime"])
      success
    rescue JSON::ParserError
      error("Response from Divvy was not valid JSON")
    end

    private

    def log_prefix
      "DIVVY"
    end

    def http
      @http ||= Net::HTTP.new("feeds.divvybikes.com", 443)
      @http.use_ssl = true
      @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      @http
    end
  end
end
