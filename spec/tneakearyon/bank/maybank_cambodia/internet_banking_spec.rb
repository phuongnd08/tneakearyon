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
    let(:tac) { "123456" }

    let(:options) { { :to_account => to_account, :amount => amount, :email => email, :tac => tac } }
    let(:result) { subject.create_third_party_transfer!(options) }

    let(:asserted_from_account_number) { ENV["TNEAKEARYON_TEST_FILTERED_DATA_ACCOUNT_NUMBER_1"] }
    let(:asserted_to_account_name) { ENV["TNEAKEARYON_TEST_FILTERED_DATA_THIRD_PARTY_TRANSFER_TO_ACCOUNT_NAME"] }
    let(:asserted_reference_number) { "0001316470" }

    def assert_transfer!
      expect(result.amount).to eq(amount)
      expect(result.from_account_number).to eq(asserted_from_account_number)
      expect(result.to_account_number).to eq(to_account)
      expect(result.to_account_name).to eq(asserted_to_account_name)
      expect(result.email).to eq(email)
      expect(result.effective_date).to be_a(Date)
    end

    context "the :to_account is incorrect" do
      let(:to_account) { "wrong" }

      before do
        do_internet_banking_request!(:cassette => "maybank_cambodia/web_client/execute_third_party_transfer_invalid_third_party_account_number") { result }
      end

      it { expect(result.error_message).to eq("The 3rd party account number is invalid.") }
    end

    context "the tac_value is invalid" do
      let(:asserted_error_message) { "Inactive TAC, please request for new TAC. [MA2]" }

      before do
        do_internet_banking_request!(:cassette => "maybank_cambodia/web_client/execute_third_party_transfer_invalid_tac") { result }
      end

      def assert_transfer!
        super
        expect(result.error_message).to eq(asserted_error_message)
        expect(result.status).to eq("Unsuccessful")
        expect(result.reason).to eq(asserted_error_message)
        expect(result.reference_number).to eq(asserted_reference_number)
        expect(result.transfer_date).to be_a(Date)
        expect(result.transfer_time).to be_a(Time)
      end

      it { assert_transfer! }
    end
  end
end
