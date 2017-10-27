module CanadaPost
  module Request
    class Manifest < Base
      attr_accessor :phone, :destination, :group_id

      def create(options)
        if options.present?
          @options = options
          @phone = options[:phone]
          @destination = options[:destination]
          @group_id = options[:group_id]
        end

        send_request :post, manifest_url, body: build_xml
      end

      def get_artifact(url)
        get_request url, headers: {'Accept' => 'application/pdf'}
      end

      private

      def request_content_type
        'manifest'
      end

      def api_version
        'v8'
      end

      def manifest_url
        "/rs/#{@credentials.customer_number}/#{@credentials.customer_number}/manifest"
      end

      def build_xml
        build :'transmit-set' do |xml|
          if @options[:shipping_point_id]
            xml.send(:'shipping-point-id', @options[:shipping_point_id])
          else
            rsp = @destination[:address_details][:postal_code].gsub(' ', '')
            xml.send(:'cpc-pickup-indicator', true)
            xml.send(:'requested-shipping-point', rsp)
          end
          xml.send(:'group-ids') {
            xml.send(:'group-id', @group_id)
          }
          xml.send(:'detailed-manifests', true)
          xml.send(:'method-of-payment', @options[:method_of_payment] || 'Account')
          xml.send(:'manifest-address') {
            add_manifest_details(xml)
          }
        end
      end

      def add_manifest_details(xml)
        xml.send(:'manifest-company', @destination[:company])
        xml.send(:'manifest-name', @destination[:name]) if @destination[:name]
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
