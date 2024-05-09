module Paperclip
  module Logger
    # Log a paperclip-specific line. This will log to ActiveRecord::Base.logger
    # by default. Set Paperclip.options[:log] to false to turn off.
    def log(message)
      logger.send(level, "[paperclip] #{message}") if logging?
    end

    def logger #:nodoc:
      @logger ||= options[:logger]
    end

    def level
      @level ||= options[:log_level]
    end

    def logger=(logger)
      @logger = logger
    end

    def logging? #:nodoc:
      options[:log]
    end
  end
end
