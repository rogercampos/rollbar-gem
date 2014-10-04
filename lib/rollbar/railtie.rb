require 'rails/railtie'
require 'rollbar'

module Rollbar
  class Railtie < ::Rails::Railtie
    rake_tasks do
      require 'rollbar/rake_tasks'
    end

    if defined? ActiveRecord
      initializer 'rollbar.middleware.rails' do |app|
        require 'rollbar/middleware/rails/rollbar_request_store'
        require 'rollbar/middleware/rails/show_exceptions'
        app.config.middleware.insert_before 'ActionDispatch::ShowExceptions', 'Rollbar::Middleware::Rails::ShowExceptions'
        app.config.middleware.use 'Rollbar::Middleware::Rails::RollbarRequestStore'
      end
    end

    config.after_initialize do
      Rollbar.preconfigure do |config|
        config.logger ||= ::Rails.logger
        config.environment ||= ::Rails.env
        config.root ||= ::Rails.root
        config.framework = "Rails: #{::Rails::VERSION::STRING}"
        config.filepath ||= ::Rails.application.class.parent_name + '.rollbar'
      end

      ActiveSupport.on_load(:action_controller) do
        # lazily load action_controller methods
        require 'rollbar/rails/controller_methods'
        include Rollbar::Rails::ControllerMethods
      end
    end
  end
end
