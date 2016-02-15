module CanadaPost
  module Request
    class Registration < Base
      def initialize(credential)
        @credentials = credential
        super(credential)
      end

      def process_request
        api_response = self.class.post(
            api_url,
            headers: api_header,
            basic_auth: @authorization
        )
        shipping_response = process_response(api_response)
        puts shipping_response.inspect
        if shipping_response[:token].present?
          token_id = shipping_response[:token][:token_id]
        end
        return token_id
      end

      def marchant_info(token)
        marchant_url = api_url + "/#{token}"
        api_response = self.class.get(
            marchant_url,
            headers: api_header,
            basic_auth: @authorization
        )
        process_response(api_response)
      end

      private

      def api_header
        {
            'Accept-Language' => 'en-CA',
            'Accept' => 'application/vnd.cpc.registration+xml'
        }
      end

      def api_url
        api_url = @credentials.mode == "production" ? PRODUCTION_URL : TEST_URL
        api_url += "/ot/token"
      end
    end
  end
end