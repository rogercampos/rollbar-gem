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
              key = 'action_dispatch.show_detailed_exceptions'

              # don't report production exceptions here as it is done below
              # in call_with_rollbar() when show_detailed_exception is false
              if not env.has_key?(key) or env[key]
                report_exception_to_rollbar(env, exception)
              end
            end
          end
        end
      end
    end
  end
end
