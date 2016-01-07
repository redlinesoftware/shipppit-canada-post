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
    let(:package) { {weight: 2, dimension: {length: 25, width: 15, height: 10}} }
    let(:sender) { {name: '', company: '', phone: '', address_details: {address: '', city: '', zip: '', country: '', state: ''}} }
    let(:destination) { {name: '', company: '', address_details: {address: '', city: '', zip: '', country: '', state: ''}} }
    let(:notification) { {email: '', on_shipment: '', on_exception: '', on_delivery: ''} }
    let(:preferences) { {show_packing_instructions: '', show_postage_rate: '', show_insured_value: ''} }
    let(:group_id) { {value: ''} }
    let(:mailing_date) { {value: ''} }
    let(:service_code) { {value: ''} }

    context 'domestic shipment', :vcr do
      let(:shipping) {
        canada_post_service.create(sender: sender,
                                   destination: destination,
                                   package: package,
                                   notification: notification,
                                   preferences: preferences,
                                   group_id: group_id[:value],
                                   mailing_date: mailing_date[:value],
                                   service_code: service_code[:value]) }
    end
  end

end