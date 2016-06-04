require 'spec_helper'

describe Tneakearyon::Bank::MaybankCambodia::InternetBanking do
  subject { described_class.new }

  describe "#login_details" do
    let(:result) { subject.login_details }

    def fetch_login_details!(options = {})
      VCR.use_cassette(options[:cassette]) do
        result
      end
    end

    context "given the correct credentials" do
      # assumes correct credentials are set in .env
      before do
        fetch_login_details!(:cassette => "maybank_cambodia/web_client/fetch_login_details")
      end

      it { expect(result.name).not_to eq(nil) }
    end

    context "given incorrect credentials" do
      subject { described_class.new(:username => "wrong", :password => "wrong") }
      it { expect { fetch_login_details!(:cassette => "maybank_cambodia/web_client/incorrect_credentials") }.to raise_error(RuntimeError) }
    end
  end
end
