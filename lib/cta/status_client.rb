require "net/http"
require "json"
require "active_support/core_ext/time"

require_relative "../base_client"

module CTA
  class StatusClient
    include BaseClient
    include Timezone::Chicago

    attr_reader :routes

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

    private

    def log_prefix
      "CTA STATUS"
    end

    def http
      @http ||= Net::HTTP.new("www.transitchicago.com", 80)
    end
  end
end
