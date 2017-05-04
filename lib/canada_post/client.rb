module CanadaPost
  class Client

    def initialize(options={})
      @credentials = Credentials.new(options)
    end

    def shipment(options={})
      Request::Shipment.new(@credentials, options).process_request
    end

    def create(options = {})
      Request::Shipping.new(@credentials, options).process_request
    end

    def get_price(shipping_id, mobo = @credentials.customer_number)
      Request::Shipping.new(@credentials).get_price(shipping_id, mobo)
    end

    def get_label(label_url)
      Request::Shipping.new(@credentials).get_label(label_url)
    end

    def void_shipment(shipping_id, mobo = @credentials.customer_number)
      Request::Shipping.new(@credentials).void_shipping(shipping_id, mobo)
    end

    def manifest(options={})
      Request::Manifest.new(@credentials, options).process_request
    end

    def registration_token
      Request::Registration.new(@credentials).get_token
    end

    def get_merchant_info(token)
      Request::Registration.new(@credentials).merchant_info(token)
    end

    def get_artifact(url)
      manifest = Request::Manifest.new(@credentials).get_manifest(url)
      if manifest[:errors].present?
        return {
            status: false,
            error: manifest[:errors]
        }
      else
        artifact_link = get_artifact_link(manifest[:manifest])
        artifact = Request::Manifest.new(@credentials).get_artifact(artifact_link)
        return {
            status: true,
            artifact: artifact
        }
      end
    end

    def get_artifact_link(manifest)
      links = manifest[:links]
      if links.present?
        links[:link].each do |link|
          if link[:rel] == 'artifact'
            return link[:href]
          end
        end
      end
    end

    def summary(shipping_id)
      Request::Shipping.new(@credentials).summary(shipping_id)
    end

    def details(shipping_id)
      Request::Shipping.new(@credentials).details(shipping_id)
    end

    def rate(options={})
      Request::Rate.new(@credentials, options).process_request
    end

  end
end
