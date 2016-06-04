class Tneakearyon::Bank::MaybankCambodia::InternetBanking
  attr_accessor :client, :bank_accounts, :login_details

  def initialize(options = {})
    self.client = options[:client] || Tneakearyon::Bank::MaybankCambodia::WebClient.new(options)
  end

  def login_details
    @login_details ||= fetch_login_details
  end

  def bank_accounts
    @bank_accounts ||= fetch_bank_accounts
  end

  def create_transfer!(options = {})
    transfer_response = client.transfer!(options)
    Tneakearyon::Transfer.new(:amount => transfer_response[:amount])
  end

  private

  def fetch_login_details
    login_details = client.fetch_login_details!
    Tneakearyon::LoginDetails.new(:name => login_details[:name])
  end

  def fetch_bank_accounts
    self.bank_accounts = []
    client.fetch_bank_accounts!.each do |bank_account|
      self.bank_accounts << Tneakearyon::BankAccount.new(
        :number => bank_account[:number],
        :current_balance => bank_account[:current_balance],
        :available_balance => bank_account[:available_balance]
      )
    end
    bank_accounts
  end
end
