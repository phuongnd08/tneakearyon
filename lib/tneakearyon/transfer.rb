class Tneakearyon::Transfer
  attr_accessor :error_message, :from_account_number,
                :to_account_number, :to_account_name, :email,
                :effective_date, :amount

  def initialize(params = {})
    self.error_message = params[:error_message]
    self.amount = params[:amount]
    self.from_account_number = params[:from_account_number]
    self.to_account_number = params[:to_account_number]
    self.to_account_name = params[:to_account_name]
    self.email = params[:email]
    self.effective_date = params[:effective_date]
  end
end
