module CanadaPost
  module Request
    class Rate < Base

      attr_accessor :shipper, :recipient, :package

      def initialize(credentials, options={})
        requires!(options, :shipper, :recipient, :package)
        @credentials = credentials
        @shipper, @recipient, @package, @service_type = options[:shipper], options[:recipient], options[:package], options[:service_type]
        super(credentials)
      end

      def process_request
        api_response = client(rate_url, build_xml, rate_headers)
        response = parse_response(api_response)

        if success?(response)
          rate_reply_details = response[:price_quotes][:price_quote] || []
          rate_reply_details = [rate_reply_details] if rate_reply_details.is_a? Hash
          rate_reply_details.map do |rate_reply|
            CanadaPost::Rate.new(rate_reply)
          end
        else
          error_message =
            if response[:messages]
              response[:messages][:message][:description]
            else
              'api_response.response'
            end
          raise RateError, error_message
        end
      end

      private

      def rate_url
        api_url + "/rs/ship/price"
      end

      def rate_headers
        {
          'Content-type' => 'application/vnd.cpc.ship.rate-v3+xml',
          'Accept' => 'application/vnd.cpc.ship.rate-v3+xml'
        }
      end

      def build_xml
        ns = "http://www.canadapost.ca/ws/ship/rate-v3"
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.send(:"mailing-scenario", xmlns: ns) {
            add_requested_shipment(xml)
          }
        end
        builder.doc.root.to_xml
      end

      def add_requested_shipment(xml)
        xml.send(:"customer-number", @customer_number)
        add_package(xml)
        add_services(xml)
        add_shipper(xml)
        add_recipient(xml)
      end

      def add_shipper(xml)
        xml.send(:"origin-postal-code", @shipper[:postal_code])
      end

      def add_recipient(xml)
        xml.destination {
          add_destination(xml)
        }
      end

      def add_package(xml)
        xml.send(:"parcel-characteristics") {
          xml.weight @package[:weight][:value]
          if @package[:dimensions]
            xml.dimensions {
              xml.height @package[:dimensions][:height].round(1)
              xml.width @package[:dimensions][:width].round(1)
              xml.length @package[:dimensions][:length].round(1)
            }
          end
          if @package[:cylinder]
            xml.send(:"mailing-tube", @package[:cylinder])
          end
        }
      end

      def add_destination(xml)
        if @recipient[:country_code] == "CA"
          xml.domestic {
            xml.send(:"postal-code", @recipient[:postal_code])
          }
        elsif @recipient[:country_code] == "US"
          xml.send(:"united-states") {
            xml.send(:"zip-code", @recipient[:postal_code])
          }
        else
          xml.international {
            xml.send(:"country-code", @recipient[:country_code])
          }
        end
      end

      def add_services(xml)
        if @service_type
          xml.services {
            xml.send(:"service-code", @service_type)
          }
        end
      end

      def success?(response)
        response[:price_quotes]
      end

    end
  end
end
