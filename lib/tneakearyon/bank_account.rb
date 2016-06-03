class Tneakearyon::BankAccount
  attr_accessor :number, :current_balance, :available_balance

  def initialize(params = {})
    self.number = params[:number]
    self.current_balance = params[:current_balance]
    self.available_balance = params[:available_balance]
  end
end
