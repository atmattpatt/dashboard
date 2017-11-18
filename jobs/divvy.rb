DIVVY_CLIENT = Divvy::Client.new(watch_stations: %w(339 401 402 403))

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
