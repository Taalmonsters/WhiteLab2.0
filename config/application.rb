require File.expand_path('../boot', __FILE__)

require 'csv'
require 'rails'

%w(
  active_record
  action_controller
  action_mailer
  action_view
  active_resource
  active_job
  active_model
  active_support
  active_concern
  sprockets
).each do |framework|
  begin
    require "#{framework}/railtie"
  rescue LoadError
  end
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module WhitelabV20
  class Application < Rails::Application
    config.i18n.enforce_available_locales = false
    config.i18n.default_locale = :nl
    config.i18n.load_path += Dir["#{Rails.root.to_s}/config/locales/**/*.{rb,yml}"]
    # config.x.database_type = 'blacklab'
    # config.x.database_url = 'http://localhost:8080/blacklab-server/cgnsonar/'
    config.x.database_type = 'neo4j'
    config.x.database_url = 'http://localhost:7474/'
    config.x.total_token_count = -1
    config.x.audio_dir = ENV['WHITELAB_AUDIO_DIR']
  end
end

::NEO4J_USER = ENV['NEO4J_USER']
::NEO4J_PW = ENV['NEO4J_PW']
::BACKEND_TIMEOUT_SECONDS = 600
::METADATUM_VALUES_MAX = 100 # Max number of metadatum values in filter value selection
::EXPORT_LIMIT = 100000 # Max number of hits to export
::FILTER_TOKEN_SAFE_LIMIT = 500000
