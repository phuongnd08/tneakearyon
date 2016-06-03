class Tneakearyon::LoginDetails
  attr_accessor :name

  def initialize(params = {})
    self.name = params[:name]
  end
end
