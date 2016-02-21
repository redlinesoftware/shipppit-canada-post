require 'spec_helper'
require 'canada_post'
require 'canada_post/shipment'
require 'canada_post/client'

describe CanadaPost::Shipment do
  context 'missing required parameters' do
    it 'does raise Rate exception' do
      expect { CanadaPost::Client.new }.to raise_error(CanadaPost::RateError)
    end
  end

  context 'required parameters present' do
    it 'does create a valid instance' do
      expect(CanadaPost::Client.new(canada_post_credentials)).to be_an_instance_of(CanadaPost::Client)
    end
  end

  describe 'Shipment shipping service' do
    let(:canada_post_service) { CanadaPost::Client.new(canada_post_credentials) }
    let(:package) { {weight: 2, unpackaged: false, mailing_tube: false, dimensions: {length: 2, width: 2, height: 2}} }
    let(:sender) { {name: 'nazrul', company: 'my company', phone: '34343434', shipping_point: 'H2B1A0', address_details: {address: 'test address road', city: 'MONTREAL', state: 'QC', country: 'CA', postal_code: 'H2B1A0'}} }
    let(:destination) { {name: 'nazrul recp', company: 'your company', address_details: {address: 'test dest address', city: 'Ottawa', state: 'ON', country: 'CA', postal_code: 'K1P5Z9'}} }
    let(:notification) { {email: 'user@gmail.com', on_shipment: 'true', on_exception: 'true', on_delivery: 'true'} }
    let(:preferences) { {show_packing_instructions: 'true', show_postage_rate: 'false', show_insured_value: 'true'} }
    let(:group_id) { {value: '5241557'} }
    let(:mailing_date) { {value: "#{Date.today + 5}"} }
    let(:service_code) { {value: 'DOM.EP'} }
    let(:contract_number) { {value: '42708517'} }
    let(:mobo) { {
        username: 'xxx',
        password: 'password',
        customer_number: '123456789',
        contract_number: '987654321'}
    }

    context 'create shipment', :vcr do
      let(:shipping) {
        canada_post_service.create(sender: sender,
                                   destination: destination,
                                   package: package,
                                   notification: notification,
                                   preferences: preferences,
                                   group_id: group_id[:value],
                                   mailing_date: mailing_date[:value],
                                   service_code: service_code[:value],
                                   contract_number: contract_number[:value]) }

      it 'Should create a shipping' do
        expect(shipping[:create_shipping][:errors]).to be_nil
      end

      it 'Should get a shipping id' do
        expect(shipping[:create_shipping][:shipment_info][:shipment_id]).not_to be_nil
      end

      it 'Should transmit shipping' do
        expect(shipping[:transmit_shipping][:errors]).to be_nil
      end

      it 'Should create manifest link for shipping' do
        expect(shipping[:transmit_shipping][:manifests]).not_to be_nil
      end

      let(:get_shipment) {
        canada_post_service.details(shipping[:create_shipping][:shipment_info][:shipment_id])
      }

      it 'Should get shipping details' do
        expect(get_shipment[:shipment_details]).not_to be_nil
      end

      it 'Should shipping status be transmitted' do
        expect(get_shipment[:shipment_details][:shipment_status]).to eq 'transmitted'
      end

      let(:get_price) {
        canada_post_service.get_price(shipping[:create_shipping][:shipment_info][:shipment_id])
      }

      it 'Should get shipping price' do
        expect(get_price[:shipment_price]).not_to be_nil
      end

      let(:void_shipping) {
        canada_post_service.void_shipment(shipping[:create_shipping][:shipment_info][:shipment_id])
      }

      it 'Should void' do
        expect(void_shipping[:errors]).to be_nil
      end

    end

    context "Create shipping mail behind of", :vcr do
      let(:shipping) {
        canada_post_service.create(sender: sender,
                                   destination: destination,
                                   package: package,
                                   mobo: mobo,
                                   notification: notification,
                                   preferences: preferences,
                                   group_id: group_id[:value],
                                   mailing_date: mailing_date[:value],
                                   service_code: service_code[:value],
                                   contract_number: contract_number[:value])
      }

      let(:get_shipment) {
        canada_post_service.details(shipping[:create_shipping][:shipment_info][:shipment_id], mobo[:customer_number])
      }

      it 'Should create a shipping' do
        expect(shipping[:create_shipping][:errors]).to be_nil
      end

      it 'Should get a mobo shipping id' do
        expect(shipping[:create_shipping][:shipment_info][:shipment_id]).not_to be_nil
      end

      it 'Should transmit mobo shipping' do
        expect(shipping[:transmit_shipping][:errors]).to be_nil
      end

      it 'Should get mobo shipping details' do
        expect(get_shipment[:shipment_details]).not_to be_nil
      end
    end
  end
end
