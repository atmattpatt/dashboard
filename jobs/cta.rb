require "net/http"
require "json"
require "active_support/core_ext/time"

module CTA
  class StatusClient
    attr_reader :error_message, :routes, :updated_at

    def initialize(watch_routes: [])
      @watch_routes = watch_routes.each_with_object({}) do |route_data, memo|
        id, display = route_data.split("=")
        memo[id] = display
      end

      @success = false
      @error_message = nil
      @routes = []
      @updated_at = nil
    end

    def fetch
      response = http.request(Net::HTTP::Get.new("/api/1.0/routes.aspx?outputType=JSON"))

      unless response.code == "200"
        return error("Could not fetch CTA route status (HTTP #{response.code})")
      end

      parsed_response = JSON.parse(response.body)
      all_routes = parsed_response.fetch("CTARoutes", {}).fetch("RouteInfo", [])

      log "Got status for #{all_routes.length} routes"

      @routes = all_routes.each_with_object([]) do |route, memo|
        next unless @watch_routes.key?(route["ServiceId"])

        memo << {
          route: @watch_routes[route["ServiceId"]] || route["ServiceId"],
          route_color_code: route["RouteColorCode"],
          route_status: route["RouteStatus"],
        }
      end
      @updated_at = timezone.parse(parsed_response["CTARoutes"]["TimeStamp"])
      success
    rescue JSON::ParserError
      error("Response from CTA was not valid JSON")
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
      puts "[CTA STATUS] #{message}"
    end

    def http
      @http ||= Net::HTTP.new("www.transitchicago.com", 80)
    end

    def timezone
      @timezone ||= ActiveSupport::TimeZone["Central Time (US & Canada)"]
    end
  end
end

CTA_STATUS_CLIENT = CTA::StatusClient.new(watch_routes: %w(Red Blue Brn=Brown G=Green Org=Orange Pink 24 31))

SCHEDULER.every '1m', first_in: 0 do |job|
  CTA_STATUS_CLIENT.fetch

  send_event(
    'cta-status',
    success: CTA_STATUS_CLIENT.success?,
    updated_at: CTA_STATUS_CLIENT.updated_at.to_s(:time),
    error: CTA_STATUS_CLIENT.error_message,
    items: CTA_STATUS_CLIENT.routes,
  )
end
