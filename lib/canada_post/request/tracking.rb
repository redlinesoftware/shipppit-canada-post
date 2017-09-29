require 'canada_post/request/manifest'

module CanadaPost
  module Request
    class Tracking < Base
      def summary(tracking_id)
        get_request "/#{tracking_id}/summary"
      end

      def details(shipping_id)
        get_request "/#{tracking_id}/detail"
      end

      private

      def base_url
        "/vis/track/pin"
      end

      def request_content_type
        'track'
      end
    end
  end
end
