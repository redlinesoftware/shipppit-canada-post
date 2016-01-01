require 'spec_helper'
require 'canada_post'
require 'canada_post/client'

describe CanadaPost::Client do

  context 'missing required parameters' do
    it 'does raise Rate exception' do
      expect{ CanadaPost::Client.new }.to raise_error(CanadaPost::RateError)
    end
  end

  context 'required parameters present' do
    it 'does create a valid instance' do
      expect( CanadaPost::Client.new(canada_post_credentials) ).to be_an_instance_of(CanadaPost::Client)
    end
  end

  describe 'rate service' do
    let(:canada_post) { CanadaPost::Client.new(canada_post_credentials) }
    let(:simple_package)  { { weight: {value: 2, units: "KG"} } }
    let(:complex_package) { { weight: {value: 2, units: "KG"}, dimension: {length: 25, width: 15, height: 10, units: "CM"} } }
    let(:mailing_tube) { { cylinder: true, weight: {value: 2, units: "KG"}, dimension: {length: 25, width: 15, height: 10, units: "CM"} } }
    let(:shipper) { { postal_code: "M5X1B8", country_code: "CA" } }
    let(:domestic_recipient) { { postal_code: "M5R1C6", country_code: "CA" } }
    let(:us_recipient) { { postal_code: "10012", country_code: "US", residential: true } }
    let(:intl_recipient) { { country_code: "GB" } }

    context 'domestic shipment', :vcr do
      let(:rates) {
        canada_post.rate(shipper: shipper, recipient: domestic_recipient, package: simple_package) }
      it 'does return a rate' do
        expect(rates.first).to be_an_instance_of(CanadaPost::Rate)
      end
      it 'does return a cost' do
        expect(rates.first.total_net_charge).not_to be_nil
      end
      it 'does return a service_code' do
        expect(rates.first.service_code).not_to be_nil
      end
      it 'does return expected_transit_time' do
        expect(rates.first.expected_transit_time).not_to be_nil
      end
      it 'does return guaranteed_delivery' do
        expect(rates.first.guaranteed_delivery).not_to be_nil
      end
      it 'does return expected_delivery_date' do
        expect(rates.first.expected_delivery_date).not_to be_nil
      end
    end

    context 'with package options specified', :vcr do
      let(:rates) {
        canada_post.rate(shipper: shipper, recipient: domestic_recipient, package: mailing_tube) }
      it 'does return a rate' do
        expect(rates.first).to be_an_instance_of(CanadaPost::Rate)
      end
    end

    context 'with service type specified', :vcr do
      let(:rates) { canada_post.rate(shipper: shipper, recipient: domestic_recipient, package: simple_package, service_type: "DOM.RP") }

      it 'returns a single rate' do
        expect(rates.count).to eq 1
      end

      it 'has a service_type attribute' do
        expect(rates.first.service_type).to eq("Regular Parcel")
      end
    end

    context 'with no service type specified', :vcr do
      let(:rates) { canada_post.rate(shipper: shipper, recipient: domestic_recipient, package: simple_package) }
      it 'returns multiple rates' do
        expect(rates.count).to be >= 1
      end

      context 'each rate' do
        it 'has service type attribute' do
          expect(rates.first).to respond_to(:service_type)
        end
      end
    end

    context 'when there are no valid services available', :vcr do
      let(:bad_shipper) { shipper.merge(postal_code: '0') }
      let(:rates) { canada_post.rate(shipper: bad_shipper, recipient: domestic_recipient, package: simple_package) }

      it 'does raise Rate exception' do
        expect{ rates }.to raise_error(CanadaPost::RateError)
      end
    end

  end

end
