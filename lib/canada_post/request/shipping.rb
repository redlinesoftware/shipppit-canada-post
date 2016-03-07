require 'canada_post/request/manifest'
module CanadaPost
  module Request
    class Shipping < Base

      attr_accessor :sender, :destination, :package, :notification, :preferences, :settlement_info, :group_id, :mailing_date, :contract_id

      def initialize(credentials, options={})
        @credentials = credentials
        if options.present?
          @sender = options[:sender]
          @destination = options[:destination]
          @package = options[:package]
          @notification = options[:notification]
          @preferences = options[:preferences]
          @settlement_info = options[:settlement_info]
          @group_id = options[:group_id]
          @mobo = options[:mobo]
          if @mobo.present? && @mobo[:customer_number].present?
            @mobo_customer = @mobo[:customer_number]
            @shipping_auth = {username: @mobo[:username], password: @mobo[:password]}
          else
            @mobo_customer = @credentials.customer_number
            @shipping_auth = {username: credentials.username, password: credentials.password}
          end
          @customer_number = @credentials.customer_number
          @mailing_date = options[:mailing_date]
          @contract_id = options[:contract_id]
          @service_code = options[:service_code]
        end
        super(credentials)
      end

      def process_request
        shipment_response = Hash.new
        api_response = self.class.post(
          shipping_url,
          body: build_xml,
          headers: shipping_header,
          basic_auth: @shipping_auth
        )
        shipping_response = process_response(api_response)
        shipment_response[:create_shipping] = shipping_response
        unless shipping_response[:errors].present?
          manifest_params = {
            destination: @destination,
            phone: @sender[:phone],
            group_id: @group_id
          }
          manifest_response = CanadaPost::Request::Manifest.new(@credentials, manifest_params).process_request
          shipment_response[:transmit_shipping] = manifest_response
        end
        shipment_response
      end

      def get_price(shipping_id, mobo = @credentials.customer_number)
        price_url = api_url + "/rs/#{@credentials.customer_number}/#{mobo}/shipment/#{shipping_id}/price"
        api_response = self.class.get(
          price_url,
          headers: shipping_header,
          basic_auth: @authorization
        )
        process_response(api_response)
      end

      def details(shipping_id, mobo = @credentials.customer_number)
        details_url = api_url + "/rs/#{@credentials.customer_number}/#{mobo}/shipment/#{shipping_id}/details"
        api_response = self.class.get(
          details_url,
          headers: shipping_header,
          basic_auth: @authorization
        )
        process_response(api_response)
      end

      def get_label(label_url)
        self.class.get(
          label_url,
          headers: {
            'Content-type' => 'application/pdf',
            'Accept' => 'application/pdf'
          },
          basic_auth: @authorization
        )
      end

      def void_shipping(shipping_id, mobo = @credentials.customer_number)
        void_url = api_url + "/rs/#{@credentials.customer_number}/#{mobo}/shipment/#{shipping_id}"
        api_response = self.class.delete(
            void_url,
            headers: shipping_header,
            basic_auth: @authorization
        )
        process_response(api_response)
      end

      private

        def api_url
          @credentials.mode == "production" ? PRODUCTION_URL : TEST_URL
        end

        def shipping_url
          base_url = api_url
          if @mobo.present? && @mobo[:customer_number].present?
            base_url += "/rs/#{@mobo_customer}-#{@customer_number}/#{@mobo_customer}/shipment"
          else
            base_url += "/rs/#{@customer_number}/#{@customer_number}/shipment"
          end
          base_url
        end

        def shipping_header
          header = {
            'Content-type' => 'application/vnd.cpc.shipment-v7+xml',
            'Accept' => 'application/vnd.cpc.shipment-v7+xml'
          }
          if @mobo.present? && @mobo[:customer_number].present?
            header['Platform-id'] = @customer_number
          end
          header
        end

        def build_xml
          ns = "http://www.canadapost.ca/ws/shipment-v7"
          builder = Nokogiri::XML::Builder.new do |xml|
            xml.send(:"shipment", xmlns: ns) {
              add_shipment_params(xml)
            }
          end
          builder.doc.root.to_xml
        end

        def add_shipment_params(xml)
          if @group_id.present?
            xml.send(:'group-id', @group_id)
          end
          if @mailing_date.present?
            xml.send(:'expected-mailing-date', @mailing_date)
          end
          sender_zip = @sender[:address_details][:postal_code].present? ? @sender[:address_details][:postal_code].gsub(' ', '') : ''
          rsp = @sender[:shipping_point].present? ? @sender[:shipping_point].gsub(' ', '') : sender_zip
          xml.send(:'requested-shipping-point', rsp)
          xml.send(:'delivery-spec') {
            add_delivery_spec(xml)
          }
        end

        def add_delivery_spec(xml)
          xml.send(:'service-code', @service_code) if @service_code.present?
          xml.send(:'sender') {
            add_sender(xml)
          }

          xml.send(:'destination') {
            add_destination(xml)
          }

          add_package(xml)
          xml.send(:'print-preferences') {
            xml.send(:'output-format', '8.5x11')
          }

          xml.notification {
            xml.send(:'email', @notification[:email])
            xml.send(:'on-shipment', @notification[:on_shipment])
            xml.send(:'on-exception', @notification[:on_exception])
            xml.send(:'on-delivery', @notification[:on_delivery])
          }

          xml.preferences {
            xml.send(:'show-packing-instructions', @preferences[:show_packing_instructions])
            xml.send(:'show-postage-rate', @preferences[:show_postage_rate])
            xml.send(:'show-insured-value', @preferences[:show_insured_value])
          }

          xml.send(:'settlement-info') {
            contract_id = @credentials.mode == "production" ? @contract_id : TEST_CONTRACT_ID
            xml.send(:'contract-id', contract_id)
            if @mobo.present? && @mobo[:customer_number].present?
              xml.send(:'paid-by-customer', @mobo_customer)
            end
            xml.send(:'intended-method-of-payment', 'Account')
          }
        end

        def add_sender(xml)
          xml.send(:'name', @sender[:name])
          xml.send(:'company', @sender[:company])
          xml.send(:'contact-phone', @sender[:phone])
          xml.send(:'address-details') {
            add_address(xml, @sender[:address_details])
          }
        end

        def add_destination(xml)
          xml.send(:'name', @destination[:name])
          xml.send(:'company', @destination[:company])
          xml.send(:'address-details') {
            add_address(xml, @destination[:address_details])
          }
        end

        def add_address(xml, params)
          xml.send(:'address-line-1', params[:address])
          xml.send(:'city', params[:city])
          xml.send(:'prov-state', params[:state])
          xml.send(:'country-code', params[:country])
          if params[:postal_code].present?
            xml.send(:'postal-zip-code', params[:postal_code].gsub(' ', ''))
          end
        end

        def add_package(xml)
          xml.send(:"parcel-characteristics") {
            xml.unpackaged @package[:unpackaged].present? ? @package[:unpackaged] : false
            xml.send(:"mailing-tube", @package[:mailing_tube].present? ? @package[:mailing_tube] : false)
            xml.weight @package[:weight]
            if @package[:dimensions]
              xml.dimensions {
                xml.height @package[:dimensions][:height].to_f.round(1)
                xml.width @package[:dimensions][:width].to_f.round(1)
                xml.length @package[:dimensions][:length].to_f.round(1)
              }
            end
          }
        end

    end
  end
end
