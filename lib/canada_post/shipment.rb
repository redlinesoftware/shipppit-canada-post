module CanadaPost
  class Shipment

    def initialize(options={})
      @credentials = Credentials.new(options)
    end

    def create(options = {})
      Request::Shipping.new(@credentials, options).process_request
    end

    def rate(options={})
      Request::Rate.new(@credentials, options).process_request
    end
  end
end