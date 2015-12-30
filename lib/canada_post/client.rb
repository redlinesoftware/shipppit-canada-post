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

  end
end
