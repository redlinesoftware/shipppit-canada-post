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