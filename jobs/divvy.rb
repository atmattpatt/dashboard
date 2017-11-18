require "net/http"
require "json"
require "active_support/core_ext/time"

class DivvyClient
  attr_reader :error_message, :stations, :updated_at

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

  def success?
    @success
  end

  private

  def success
    @success = true
    @error_message = nil
  end

  def error(message)
    @success = false
    @error_message = message
    @updated_at = timezone.now
  end

  def log(message)
    puts "[DIVVY] #{message}"
  end

  def http
    @http ||= Net::HTTP.new("feeds.divvybikes.com", 443)
    @http.use_ssl = true
    @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    @http
  end

  def timezone
    @timezone ||= ActiveSupport::TimeZone["Central Time (US & Canada)"]
  end
end

DIVVY_CLIENT = DivvyClient.new(watch_stations: %w(339 401 402 403))

SCHEDULER.every '5m', first_in: 0 do |job|
  DIVVY_CLIENT.fetch

  send_event(
    'divvy',
    success: DIVVY_CLIENT.success?,
    updated_at: DIVVY_CLIENT.updated_at.to_s(:time),
    error: DIVVY_CLIENT.error_message,
    items: DIVVY_CLIENT.stations,
  )
end
