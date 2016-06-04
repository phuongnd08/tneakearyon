class Tneakearyon::Transfer
  attr_accessor :amount, :error_message

  def initialize(params = {})
    self.amount = params[:amount]
    self.error_message = params[:error_message]
  end
end
