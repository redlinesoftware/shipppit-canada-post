module CanadaPost
  class Client
    def initialize(options={})
      @credentials = Credentials.new(options)
    end

    def shipping
      Request::Shipping.new(@credentials)
    end

    def manifest
      Request::Manifest.new(@credentials)
    end

    def tracking
      Request::Tracking.new(@credentials)
    end

    def pickup
      Request::Pickup.new(@credentials)
    end

    def registration_token
      Request::Registration.new(@credentials).get_token
    end

    def get_merchant_info(token)
      Request::Registration.new(@credentials).merchant_info(token)
    end

    def rate(options={})
      Request::Rate.new(@credentials, options).process_request
    end
  end
end
