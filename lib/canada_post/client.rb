module CanadaPost
  class Client

    def initialize(options={})
      @credentials = Credentials.new(options)
    end

    def rate(options={})
      Request::Rate.new(@credentials, options).process_request
    end

    def shipment(options={})
      Request::Shipment.new(@credentials, options).process_request
    end

    def create(options = {})
      Request::Shipping.new(@credentials, options).process_request
    end

    def get_price(shipping_id)
      Request::Shipping.new(@credentials).get_price(shipping_id)
    end

    def get_label(label_url)
      Request::Shipping.new(@credentials).get_label(label_url)
    end

    def details(shipping_id)
      Request::Shipping.new(@credentials).details(shipping_id)
    end

    def manifest(options={})
      Request::Manifest.new(@credentials, options).process_request
    end

  end
end
