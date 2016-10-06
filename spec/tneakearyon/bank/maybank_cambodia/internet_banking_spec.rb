require 'spec_helper'

describe Tneakearyon::Bank::MaybankCambodia::InternetBanking do
  subject { described_class.new }

  def do_internet_banking_request!(options = {}, &block)
    VCR.use_cassette(options[:cassette]) { yield }
  end

  describe "#login_details" do
    let(:result) { subject.login_details }

    context "given the correct credentials" do
      # assumes correct credentials are set in .env
      before do
        do_internet_banking_request!(:cassette => "maybank_cambodia/web_client/fetch_login_details") { result }
      end

      it { expect(result.name).to eq(ENV["TNEAKEARYON_TEST_FILTERED_DATA_LOGIN_NAME"]) }
    end

    context "given incorrect credentials" do
      subject { described_class.new(:username => "wrong", :password => "wrong") }
      it { expect { do_internet_banking_request!(:cassette => "maybank_cambodia/web_client/incorrect_credentials") { result } }.to raise_error(RuntimeError) }
    end
  end

  describe "#bank_accounts" do
    let(:result) { subject.bank_accounts }

    before do
      do_internet_banking_request!(:cassette => "maybank_cambodia/web_client/fetch_bank_accounts") { result }
    end

    def assert_bank_accounts!
      bank_account = result.first
      expect(bank_account.number).to eq(ENV["TNEAKEARYON_TEST_FILTERED_DATA_ACCOUNT_NUMBER_1"])
      expect(bank_account.current_balance).to be_a(Money)
      expect(bank_account.available_balance).to be_a(Money)
    end

    it { assert_bank_accounts! }
  end

  describe "#create_third_party_transfer!(options = {})" do
    let(:to_account) { ENV["TNEAKEARYON_TEST_FILTERED_DATA_THIRD_PARTY_TRANSFER_TO_ACCOUNT_NUMBER"] }
    let(:amount) { Money.new(1, "USD") }
    let(:email) { "someone@gmail.com" }

    let(:options) { { :to_account => to_account, :amount => amount, :email => email } }
    let(:result) { subject.create_third_party_transfer!(options) }

    context "the :to_account is incorrect" do
      let(:to_account) { "wrong" }

      before do
        do_internet_banking_request!(:cassette => "maybank_cambodia/web_client/execute_third_party_transfer_invalid_third_party_account_number") { result }
      end

      it { expect(result.error_message).to eq("The 3rd party account number is invalid.") }
    end

    context "the :to_account is correct" do
      before do
        do_internet_banking_request!(:cassette => "maybank_cambodia/web_client/execute_third_party_transfer") { result }
      end

      def assert_transfer!
        expect(result.amount).to eq(amount)
        expect(result.from_account_number).to eq(ENV["TNEAKEARYON_TEST_FILTERED_DATA_ACCOUNT_NUMBER_1"])
        expect(result.to_account_number).to eq(to_account)
        expect(result.to_account_name).to eq(ENV["TNEAKEARYON_TEST_FILTERED_DATA_THIRD_PARTY_TRANSFER_TO_ACCOUNT_NAME"])
        expect(result.email).to eq(email)
        expect(result.effective_date).to be_a(Date)
      end

      it { assert_transfer! }
    end
  end
end
