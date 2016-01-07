require 'spec_helper'
require 'canada_post'
require 'canada_post/shipment'
require 'canada_post/client'

describe CanadaPost::Request::Manifest do
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
    let(:destination) { {name: '', company: '', address_details: {address: '', city: '', zip: '', country: '', state: ''}} }
    let(:group_id) { {value: ''} }
    let(:phone) { {value: ''} }

    context 'shipping manifest', :vcr do
      let(:manifest) {
        canada_post_service.manifest(destination: destination,
                                     phone: phone[:value],
                                     group_id: group_id[:value])
      }
    end
  end

end