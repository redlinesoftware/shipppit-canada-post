module CanadaPost
  module Request
    class Shipping < Base

      attr_accessor :options, :sender, :destination, :package, :notification, :preferences, :settlement_info, :group_id, :mailing_date, :contract_id

      def initialize(credentials, options = {})
        super
        @mobo_customer = @credentials.customer_number
      end

      def create(options)
        @mobo = options[:mobo]
        if @mobo.present? && @mobo[:customer_number].present?
          @mobo_customer = @mobo[:customer_number]
          @authorization = {username: @mobo[:username], password: @mobo[:password]}
        end

        if options.present?
          @options = options
          @sender = options[:sender]
          @destination = options[:destination]
          @package = options[:package]
          @notification = options[:notification]
          @preferences = options[:preferences]
          @settlement_info = options[:settlement_info]
          @group_id = options[:group_id]
          @mailing_date = options[:mailing_date]
          @contract_id = options[:contract_id]
          @service_code = options[:service_code]
        end

        send_request :post, shipping_url, body: build_xml
      end

      def get_shipment(shipping_id)
        get_request shipping_url + "/#{shipping_id}"
      end

      def get_price(shipping_id)
        get_request shipping_url + "/#{shipping_id}/price"
      end

      def get_label(label_url)
        send_request :get, label_url, headers: {'Accept' => 'application/pdf'}
      end

      def void(shipping_id)
        send_request :delete, shipping_url + "/#{shipping_id}"
      end

      def refund(shipping_id, email)
        refund_url = shipping_url + "/#{shipping_id}/refund"
        body = build(:"shipment-refund-request") do |xml|
          xml.email_ email
        end
        send_request :post, refund_url, body: body
      end

      private

        def shipping_url
          "/#{request_content_type}"
        end

        def base_url
          "/rs/#{@credentials.customer_number}/#{@mobo_customer}"
        end

        def request_content_type
          'shipment'
        end

        def api_version
          'v8'
        end

        def build_xml
          build :"shipment" do |xml|
            add_shipment_params(xml)
          end
        end

        def add_shipment_params(xml)
          if @group_id.present?
            xml.send(:'group-id', @group_id)
          end
          if @mailing_date.present?
            xml.send(:'expected-mailing-date', @mailing_date)
          end
          if @options[:shipping_point_id]
            xml.send(:'shipping-point-id', @options[:shipping_point_id])
          else
            rsp = @sender[:address_details][:postal_code].delete(' ')
            xml.send(:'cpc-pickup-indicator', true)
            xml.send(:'requested-shipping-point', rsp)
          end
          xml.send(:'delivery-spec') {
            add_delivery_spec(xml)
          }
          xml.send(:'return-spec') {
            xml.send(:'service-code', @service_code)
            xml.send(:'return-recipient') {
              add_sender xml, return_spec: true
            }
          } if @options[:return_label]
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
            xml.send(:'output-format', @options.dig(:print_preferences, :output_format) || '8.5x11')
          }

          xml.notification {
            xml.send(:'email', @notification[:email])
            xml.send(:'on-shipment', @notification[:on_shipment])
            xml.send(:'on-exception', @notification[:on_exception])
            xml.send(:'on-delivery', @notification[:on_delivery])
          } if @notification

          xml.preferences {
            xml.send(:'show-packing-instructions', @preferences[:show_packing_instructions])
            xml.send(:'show-postage-rate', @preferences[:show_postage_rate])
            xml.send(:'show-insured-value', @preferences[:show_insured_value])
          }

          xml.send(:'settlement-info') {
            if @mobo.present? && @mobo[:customer_number].present?
              xml.send(:'paid-by-customer', @mobo_customer)
            end
            xml.send(:'contract-id', @contract_id)
            xml.send(:'intended-method-of-payment', @options[:method_of_payment] || 'Account')
          }
        end

        def add_sender(xml, return_spec: false)
          xml.send(:'name', @sender[:name]) if @sender[:name]
          xml.send(:'company', @sender[:company])
          xml.send(:'contact-phone', @sender[:phone]) unless return_spec
          xml.send(:'address-details') {
            add_address(xml, @sender[:address_details], include_country: !return_spec)
          }
        end

        def add_destination(xml)
          xml.send(:'name', @destination[:name])
          xml.send(:'company', @destination[:company]) if @destination[:company]
          xml.send(:'client-voice-number', @destination[:phone])
          xml.send(:'address-details') {
            add_address(xml, @destination[:address_details])
          }
        end

        def add_address(xml, params, include_country: true)
          xml.send(:'address-line-1', params[:address])
          xml.send(:'city', params[:city])
          xml.send(:'prov-state', params[:state])
          xml.send(:'country-code', params[:country]) if include_country
          if params[:postal_code].present?
            xml.send(:'postal-zip-code', params[:postal_code].delete(' '))
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
