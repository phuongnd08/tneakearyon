require 'spec_helper'

describe Tneakearyon::Bank::ABA::MobileClient do
  let(:client) { described_class.new }

  def do_internet_banking_request!(options = {}, &block)
    VCR.use_cassette(options[:cassette]) { yield }
  end

  describe "#login!" do
    it "retrieves the token" do
      do_internet_banking_request!(:cassette => "aba/mobile_client/test_login") do
        client.login!
        expect(client.token).not_to be_nil
      end
    end
  end

  describe "#get_cards!" do
    it "retrive the cards" do
      do_internet_banking_request!(:cassette => "aba/mobile_client/test_get_cards") do
        cards = client.get_cards!
        expect(cards["cards"].count).to eq 1
      end
    end
  end
end
