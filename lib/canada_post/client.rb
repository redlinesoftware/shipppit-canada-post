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

    def get_artifact(url)
      manifest = manifest.get_request(url)
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

    def rate(options={})
      Request::Rate.new(@credentials, options).process_request
    end
  end
end
