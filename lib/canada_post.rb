require "canada_post/version"
require "canada_post/request/base"
require "canada_post/request/rate"
require "canada_post/request/shipping"
require "canada_post/request/tracking"
require "canada_post/request/manifest"
require "canada_post/request/pickup"
require "canada_post/request/registration"
require "canada_post/client"
require "canada_post/credentials"
require "canada_post/rate"

module CanadaPost
  # Exceptions: CandaPost::RateError
  class RateError < StandardError; end
  class ShipmentError < StandardError; end
end
