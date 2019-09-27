require 'httparty'
require 'nokogiri'
require 'active_support/core_ext/hash'
require 'canada_post/helpers'
require 'canada_post/rate'

module CanadaPost
  module Request
    class Base
      include Helpers
      include HTTParty

      # CanadaPost API Test URL
      TEST_URL = "https://ct.soa-gw.canadapost.ca"

      # CanadaPost API Production URL
      PRODUCTION_URL = "https://soa-gw.canadapost.ca"

      # CanadaPost API TEST CONTRACT ID
      TEST_CONTRACT_ID = "0042708517"

      # List of available Option Codes
      # SO - Signature
      # COV - Coverage  (requires qualifier)
      # COD - COD (requires qualifier)
      # PA18 - Proof of Age Required - 18
      # PA19 - Proof of Age Required - 19
      # HFP - Card for pickup
      # DNS - Do not safe drop
      # LAD - Leave at door - do not card
      OPTION_CODES = ["SO", "COV", "COD", "PA18", "PA19", "HFP", "DNS", "LAD"]

      # List of available Service Codes
      # DOM.RP - Regular Parcel
      # DOM.EP - Expedited Parcel
      # DOM.XP - Xpresspost
      # DOM.XP.CERT - Xpresspost Certified
      # DOM.PC - Priority
      # DOM.DT - Delivered Tonight
      # DOM.LIB - Library Books
      # USA.EP - Expedited Parcel USA
      # USA.PW.ENV - Priority Worldwide Envelope USA
      # USA.PW.PAK - Priority Worldwide pak USA
      # USA.PW.Parcel - Priority Worldwide Parcel USA
      # USA.SP.AIR - Small Packet USA Air
      # USA.TP - Tracked Package - USA
      # USA.TP.LVM - Tracked Package - USA (LVM) (large volume mailers)
      # USA.XP - Xpresspost USA
      # INT.XP - Xpresspost international
      # INT.IP.AIR - International Parcel Air
      # INT.IP.SURF - International Parcel Surface
      # INT.PW.ENV - Priority Worldwide Envelope Int'l
      # INT.PW.PAK - Priority Worldwide pak Int'l
      # INT.PW.PARCEL - Priority Worldwide Parcel Int'l
      # INT.SP.AIR - Small Packet International Air
      # INT.SP.SURF - Small Packet International Surface
      # INT.TP - Tracked Package - International
      SERVICE_CODES = {
        "DOM.RP" => 'Regular Parcel',
        "DOM.EP" => 'Expedited Parcel',
        "DOM.XP" => 'Xpresspost',
        "DOM.XP.CERT" => 'Xpresspost Certified',
        "DOM.PC" => 'Priority',
        "DOM.DT" => 'Delivered Tonight',
        "DOM.LIB" => 'Library Books',
        "USA.EP" => 'Expedited Parcel USA',
        "USA.PW.ENV" => 'Priority Worldwide Envelope USA',
        "USA.PW.PAK" => 'Priority Worldwide pak USA',
        "USA.PW.PARCEL" => 'Priority Worldwide Parcel USA',
        "USA.SP.AIR" => 'Small Packet USA Air',
        "USA.TP" => 'Tracked Package - USA',
        "USA.TP.LVM" => 'Tracked Package - USA (LVM) (large volume mailers)',
        "USA.XP" => 'Xpresspost USA',
        "INT.XP" => 'Xpresspost international',
        "INT.IP.AIR" => 'International Parcel Air',
        "INT.IP.SURF" => 'International Parcel Surface',
        "INT.PW.ENV" => "Priority Worldwide Envelope Int'l",
        "INT.PW.PAK" => "Priority Worldwide pak Int'l",
        "INT.PW.PARCEL" => "Priority Worldwide Parcel Int'l",
        "INT.SP.AIR" => 'Small Packet International Air',
        "INT.SP.SURF" => 'Small Packet International Surface',
        "INT.TP" => 'Tracked Package - International'
      }

      def initialize(credentials)
        @credentials = credentials
        @authorization = {username: @credentials.username, password: @credentials.password}
        @customer_number = @credentials.customer_number
      end

      def process_request
        raise NotImplementedError, "Override #process_request in subclass"
      end

      # Sends POST request to CanadaPost API and parse the response,
      # a class object (Shipment, Rate...) is created if the response is successful
      def client(url, body, headers)
        self.class.post(
          url,
          body: body,
          headers: headers,
          basic_auth: @authorization
        )
      end

      def api_url
        production? ? PRODUCTION_URL : TEST_URL
      end

      def production?
        @credentials.mode == "production"
      end

      def build(root)
        Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.send(root, xmlns: "http://www.canadapost.ca/ws/#{versioned_content_type}") {
            yield xml
          }
        end.to_xml
      end

      def build_xml
        raise NotImplementedError, "Override #build_xml in subclass"
      end

      def base_url
        ''
      end

      def api_version
        nil
      end

      def request_content_type
        raise NotImplementedError, "Override #request_content_type in subclass"
      end

      def get_request(url)
        if url.is_a?(Hash)
          url = url.with_indifferent_access
          send_request :get, url[:href], media_type: url[:media_type]
        else
          send_request :get, url
        end
      end

      def send_request(type, url, media_type: nil, headers: {}, body: nil)
        headers['Accept'] = media_type if media_type
        request_headers = {'Accept' => "application/vnd.cpc.#{versioned_content_type}+xml", 'Accept-language' => 'en-CA'}.update headers
        request_headers.update 'Content-Type' => request_headers['Accept'] if type == :post

        request_options = {
          headers: request_headers,
          basic_auth: @authorization
        }
        request_options.update body: body if body

        # determine if a full url has been provided or a relative url
        request_url = if url.match('^https:')
          # sub the production endpoint for the test endpoint if found in development
          production? ? url : url.gsub(PRODUCTION_URL, TEST_URL)
        else
          api_url + base_url + url
        end

        api_response = self.class.send type, request_url, request_options

        # return the raw response if 'Accept' is blank
        headers['Accept'].blank? ? process_response(api_response) : api_response
      end

      # Parse response, convert keys to underscore symbols
      def parse_response(response)
        response = Hash.from_xml(response.parsed_response.gsub("\n", "")) if response.parsed_response.is_a? String
        response = sanitize_response_keys(response)
      end

      def process_response(api_response)
        shipping_response = {errors: []}
        response = parse_response(api_response)
        if response[:messages].present?
          response[:messages].each do |key, message|
            shipping_response[:errors] << message if key == :message
          end
          return shipping_response
        end

        return response
      end

      private

      # Recursively sanitizes the response object by cleaning up any hash keys.
      def sanitize_response_keys(response)
        if response.is_a?(Hash)
          response.inject({}) { |result, (key, value)| result[underscorize(key).to_sym] = sanitize_response_keys(value); result }
        elsif response.is_a?(Array)
          response.collect { |result| sanitize_response_keys(result) }
        else
          response
        end
      end

      def versioned_content_type
        [request_content_type, api_version].compact.join('-')
      end

    end
  end
end
