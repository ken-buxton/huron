class User < ActiveRecord::Base
  acts_as_authentic
  before_save :set_defaults
  
  # attr_accessible :crypted_password, :login, :password_salt, :persistence_token
  attr_accessible :login, :password, :password_confirmation, :role


  protected

  def set_defaults
    self.role ||= "user"
  end

end
