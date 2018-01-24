require "howard"

require_relative "../base_client"

module CTA
  class ArrivalsClient
    include BaseClient
    include Timezone::Chicago

    attr_reader :arrivals

    def initialize(watch_stops: [], train_tracker_api_key: nil, bus_tracker_api_key: nil)
      @watch_stops = watch_stops
      @success = false
      @error_message = nil
      @arrivals = []
      @updated_at = nil

      Howard.api_keys do |key|
        key.train_tracker = train_tracker_api_key
      end
    end

    def fetch
      train_arrivals = @watch_stops.flat_map do |stop_id|
        Howard.arrivals(stop: stop_id).map do |arrival|
          {
            route: {
              full_name: arrival.route.full_name,
              color_code: arrival.route.color_code,
            },
            train: {
              run: arrival.train.run,
            },
            destination: arrival.route.destination,
            eta: arrival.eta.to_s,
          }
        end
      end

      @arrivals = train_arrivals

      log "Got #{arrivals.length} arrivals for #{@watch_stops.length} stops"
      @updated_at = Time.now
      success
    end

    private

    def log_prefix
      "CTA ARRIVALS"
    end
  end
end
