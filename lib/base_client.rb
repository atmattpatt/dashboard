module BaseClient
  def self.included(base)
    base.class_eval do
      attr_reader :error_message, :updated_at
    end
  end

  def success?
    @success
  end

  protected

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
    puts "[#{log_prefix}] #{message}"
  end

  def log_prefix
    nil
  end
end
