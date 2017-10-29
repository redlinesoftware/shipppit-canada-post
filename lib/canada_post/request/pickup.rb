module CanadaPost
  module Request
    class Pickup < Base
      def create(options)
        @address = options[:address]
        @contact = options[:contact]
        @location = options[:location]
        @pickup = options[:pickup]
        @volume = options[:pickup_volume]

        send_request :post, pickup_url, body: build_xml
      end

      private

      def build_xml
        build :"pickup-request-details" do |xml|
          xml.send :'pickup-type', 'OnDemand'
          xml.send :'pickup-location' do
            xml.send :'business-address-flag', @address.nil?
            xml.send :'alternate-address' do
              xml.send :'company', @address[:company]
              xml.send :'address-line-1', @address[:address]
              xml.send :'city', @address[:city]
              xml.send :'province', @address[:province]
              xml.send :'postal-code', @address[:postal_code]
            end if @address
          end
          xml.send :'contact-info' do
            xml.send :'contact-name', @contact[:name].truncate(45)
            xml.send :'email', @contact[:email].truncate(60)
            xml.send :'contact-phone', @contact[:phone].truncate(16)
          end
          xml.send :'location-details' do
            xml.send :'pickup-instructions', @location[:instructions].truncate(132)
          end
          xml.send :'pickup-volume', @volume.truncate(40)
          xml.send :'pickup-times' do
            xml.send :'on-demand-pickup-time' do
              xml.send :'date', @pickup[:date]
              xml.send :'preferred-time', @pickup[:time]
              xml.send :'closing-time', @pickup[:closing]
            end
          end
        end
      end

      def pickup_url
        "/enab/#{@customer_number}/#{request_content_type}"
      end

      def request_content_type
        'pickuprequest'
      end
    end
  end
end
