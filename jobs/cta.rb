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
