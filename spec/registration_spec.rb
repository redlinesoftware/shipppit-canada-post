require 'spec_helper'
require 'canada_post'
require 'canada_post/client'

describe CanadaPost::Request::Registration do
  let(:canada_post_service) { CanadaPost::Client.new(canada_post_credentials) }
  context 'missing required parameters' do
    it 'does raise Rate exception' do
      expect { CanadaPost::Client.new }.to raise_error(CanadaPost::RateError)
    end
  end

  context 'required parameters present', :vcr do
    it 'does create a valid instance' do
      expect(CanadaPost::Client.new(canada_post_credentials)).to be_an_instance_of(CanadaPost::Client)
    end

    let(:registration) {
      canada_post_service.registration_token
    }

    it 'should generate new token' do
      expect(registration[:token_id]).not_to be_nil
    end
  end
end