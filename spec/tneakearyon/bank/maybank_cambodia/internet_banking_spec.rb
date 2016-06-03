require 'spec_helper'

describe Tneakearyon::Bank::MaybankCambodia::InternetBanking do
  let(:username) { "username" }
  let(:password) { "password" }

  subject { described_class.new(:username => username, :password => password) }

  describe "#login_details" do
    context "given the correct credentials" do
      let(:result) { subject.login_details }

      def fetch_login_details!
        VCR.use_cassette(:"maybank_cambodia/web_client/fetch_login_details") do
          result
        end
      end

      before do
        fetch_login_details!
      end

      it { expect(result.name).to eq("JOE BLOGGS") }
    end
  end
end
