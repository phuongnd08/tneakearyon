$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'tneakearyon'
require_relative "support/dotenv"
require_relative "support/byebug"

Dir[File.expand_path("../support/**/*.rb", __FILE__)].each { |f| require f }
