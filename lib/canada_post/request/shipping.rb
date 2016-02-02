require 'canada_post/request/manifest'
module CanadaPost
  module Request
    class Shipping < Base

      attr_accessor :sender, :destination, :package, :notification, :preferences,
                    :settlement_info, :group_id, :mailing_date, :contract_id

      def initialize(credential, options={})
        @credentials = credential
        if options.present?
          @sender = options[:sender]
          @destination = options[:destination]
          @package = options[:package]
          @notification = options[:notification]
          @preferences = options[:preferences]
          @settlement_info = options[:settlement_info]
          @group_id = options[:group_id]
          if options[:mobo].present?
            @mobo = options[:mobo].present? ? options[:mobo] : @credentials.customer_number
            @customer = "#{@credentials.customer_number}"
          else
            @mobo = @credentials.customer_number
            @customer = @credentials.customer_number
          end
          @mailing_date = options[:mailing_date]
          @contract_id = @credentials.customer_number
          @service_code = options[:service_code]
        end
        super(credential)
      end

      def process_request
        puts "CUS: #{@customer} MOBO #{@mobo} : API URL: #{api_url}"
        shipment_response = Hash.new
        api_response = self.class.post(
          api_url,
          body: build_xml,
          headers: shipping_header,
          basic_auth: @authorization
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

      def get_price(shipping_id)
        price_url = api_url + "/#{shipping_id}/price"
        api_response = self.class.get(
          price_url,
          headers: shipping_header,
          basic_auth: @authorization
        )
        process_response(api_response)
      end

      def details(shipping_id)
        details_url = api_url + "/#{shipping_id}/details"
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

      private

      def api_url
        api_url = @credentials.mode == "production" ? PRODUCTION_URL : TEST_URL
        api_url += "/rs/#{@customer}/#{@mobo}/shipment"
      end

      def shipping_header
        {
          'Content-type' => 'application/vnd.cpc.shipment-v7+xml',
          'Accept' => 'application/vnd.cpc.shipment-v7+xml'
        }
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
