class Tneakearyon::Transfer
  attr_accessor :error_message, :from_account_number,
                :to_account_number, :to_account_name, :email,
                :effective_date, :amount, :status, :reason,
                :reference_number, :transfer_date, :transfer_time


  def initialize(params = {})
    self.error_message = params[:error_message]
    self.amount = params[:amount]
    self.from_account_number = params[:from_account_number]
    self.to_account_number = params[:to_account_number]
    self.to_account_name = params[:to_account_name]
    self.email = params[:email]
    self.effective_date = params[:effective_date]
    self.status = params[:status]
    self.reason = params[:reason]
    self.reference_number = params[:reference_number]
    self.transfer_date = params[:transfer_date]
    self.transfer_time = params[:transfer_time]
  end
end
