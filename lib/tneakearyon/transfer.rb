class Tneakearyon::Transfer
  attr_accessor :error_message

  def initialize(params = {})
    self.error_message = params[:error_message]
  end
end
