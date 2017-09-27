module CanadaPost
  module Request
    class Manifest < Base

      attr_accessor :phone, :destination, :group_id

      def initialize(credentials, options={})
        @credentials = credentials
        if options.present?
          @phone = options[:phone]
          @destination = options[:destination]
          @group_id = options[:group_id]
        end
        super(credentials)
      end

      def process_request
        api_response = self.class.post(
          api_url,
          body: build_xml,
          headers: manifest_header,
          basic_auth: @authorization
        )
        process_response(api_response)
      end

      def get_manifest(url)
        api_response = self.class.get(
          url,
          headers: manifest_header,
          basic_auth: @authorization
        )
        process_response(api_response)
      end

      def get_artifact(url)
        self.class.get(
          url,
          headers: artifact_header,
          basic_auth: @authorization
        )
      end

      private

      def api_url
        api_url = @credentials.mode == "production" ? PRODUCTION_URL : TEST_URL
        api_url += "/rs/#{@credentials.customer_number}/#{@credentials.customer_number}/manifest"
      end

      def manifest_header
        {
          'Content-type' => 'application/vnd.cpc.manifest-v8+xml',
          'Accept' => 'application/vnd.cpc.manifest-v8+xml'
        }
      end

      def artifact_header
        {
          'Content-type' => 'application/pdf',
          'Accept' => 'application/pdf'
        }
      end

      def build_xml
        ns = "http://www.canadapost.ca/ws/manifest-v8"
        xsi = 'http://www.w3.org/2001/XMLSchema-instance'
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.send(:"transmit-set", :'xmlns:xsi' => xsi, xmlns: ns) {
            xml.send(:'group-ids') {
              xml.send(:'group-id', @group_id)
            }
            xml.send(:'detailed-manifests', true)
            xml.send(:'method-of-payment', 'Account')
            xml.send(:'manifest-address') {
              add_manifest_details(xml)
            }
          }
        end
        builder.doc.root.to_xml
      end

      def add_manifest_details(xml)
        xml.send(:'manifest-company', @destination[:company])
        xml.send(:'manifest-name', @destination[:name])
        xml.send(:'phone-number', @phone)
        xml.send(:'address-details') {
          manifest_address(xml, @destination[:address_details])
        }
      end

      def manifest_address(xml, params)
        xml.send(:'address-line-1', params[:address])
        xml.send(:'city', params[:city])
        xml.send(:'prov-state', params[:state])
        if params[:postal_code].present?
          xml.send(:'postal-zip-code', params[:postal_code].gsub(' ', ''))
        end
      end

    end
  end
end
