module Hightops
  class ErrorHandler
    def handle_exception(exception, options = {})
      defined?(::Airbrake) && ::Airbrake.notify_or_ignore(exception, parameters: options)
    end
  end
end
