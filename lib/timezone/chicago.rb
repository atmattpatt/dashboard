module Timezone
  module Chicago
    def timezone
      @timezone ||= ActiveSupport::TimeZone["Central Time (US & Canada)"]
    end
  end
end
