require_relative "boot"
require "rails/all"
Bundler.require(*Rails.groups)

ENV['HOSTNAME'] =
  case `hostname`.strip
  when "bijan-ubuntu22"
    # "https://staging.visadoo.com"
    "https://visadoo.app"
  when "Ubuntu-2204-jammy-amd64-base"
    "https://visadoo.app"
  else
    # "http://localhost:5000"
    "https://visadoo.app"
  end

module Tinderbot
  class Application < Rails::Application
    config.load_defaults 7.0
    # config.time_zone = 'UTC'
    # config.time_zone = 'Eastern Time (US & Canada)'
  end
end
