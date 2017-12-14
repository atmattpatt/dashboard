require "net/http"
require "json"
require "active_support/core_ext/time"

require_relative "../base_client"

module CTA
  class AlertsClient
    include BaseClient
    include Timezone::Chicago

    attr_reader :alerts

    def initialize(watch_routes: [])
      @watch_routes = watch_routes.each_with_object({}) do |route_data, memo|
        id, display = route_data.split("=")
        memo[id] = display
      end

      @success = false
      @error_message = nil
      @alerts = []
      @updated_at = nil
    end

    def fetch
      response = http.request(Net::HTTP::Get.new("/api/1.0/alerts.aspx?outputType=JSON"))

      unless response.code == "200"
        return error("Could not fetch CTA route status (HTTP #{response.code})")
      end

      parsed_response = JSON.parse(response.body)
      all_alerts = parsed_response.fetch("CTAAlerts", {}).fetch("Alert", [])
      all_alerts = [all_alerts] if all_alerts.is_a?(Hash)

      log "Got #{all_alerts.length} alerts"

      @alerts = all_alerts.each_with_object([]) do |alert, memo|
        next unless include_alert?(alert)

        memo << {
          active: (alert["TBD"] && alert["EventStart"] && timezone.parse(alert["EventStart"]) < Time.now),
          event_end: (timezone.parse(alert["EventEnd"]) if alert["EventEnd"]),
          event_start: (timezone.parse(alert["EventStart"]) if alert["EventStart"]),
          impact: alert["Impact"],
          major_alert: alert["MajorAlert"] == "1",
          severity_score: alert["SeverityScore"],
          summary: alert["ShortDescription"],
          impacted_services: impacted_services(alert),
        }
      end.sort { |a, b| compare_alerts(a, b) }.map { |alert| format_times(alert) }

      @updated_at = timezone.parse(parsed_response["CTAAlerts"]["TimeStamp"])
      success
    rescue JSON::ParserError
      error("Response from CTA was not valid JSON")
    end

    private

    def include_alert?(alert)
      impacted_services = alert.fetch("ImpactedService", {}).fetch("Service", [])
      impacted_services = [impacted_services] if impacted_services.is_a?(Hash)

      impacted_services.any? { |service| @watch_routes.key?(service["ServiceId"]) }
    end

    def impacted_services(alert)
      impacted_services = alert.fetch("ImpactedService", {}).fetch("Service", [])
      impacted_services = [impacted_services] if impacted_services.is_a?(Hash)

      impacted_services.map do |service|
        {
          name: service["ServiceName"],
          color: service["ServiceBackColor"],
        }
      end
    end

    def format_times(alert)
      format = if alert[:event_start]&.to_date == alert[:event_end]&.to_date
                 "%H:%M"
               else
                 "%b %e %H:%M"
               end

      alert[:event_start] = alert[:event_start].strftime(format) if alert[:event_start]
      alert[:event_end] = alert[:event_end].strftime(format) if alert[:event_end]
      alert
    end

    def compare_alerts(a, b)
      case
      when a[:active] && !b[:active] then -1
      when !a[:active] && b[:active] then 1
      when a[:severity_score] != b[:severity_score] then b[:severity_score].to_i <=> a[:severity_score].to_i
      else a[:start_time] <=> b[:start_time]
      end
    end

    def log_prefix
      "CTA ALERTS"
    end

    def http
      @http ||= Net::HTTP.new("www.transitchicago.com", 80)
    end
  end
end
