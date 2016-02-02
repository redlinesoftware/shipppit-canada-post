require "canada_post/version"
require "canada_post/request/base"
require "canada_post/request/rate"
require "canada_post/request/shipping"
require "canada_post/request/registration"
require "canada_post/shipment"
require "canada_post/rate"
require "canada_post/credentials"

module CanadaPost
  # Exceptions: CandaPost::RateError
  class RateError < StandardError; end
  class ShipmentError < StandardError; end
end
