module Rollbar
  module Middleware
    module Rails
      class ShowExceptions
        include ExceptionReporter

        def initialize(app)
          @app = app
        end

        def call(env)
          @app.call(env).tap do |_|
            if exception = env["action_dispatch.exception"]
              report_exception_to_rollbar(env, exception)
            end
          end
        end
      end
    end
  end
end
