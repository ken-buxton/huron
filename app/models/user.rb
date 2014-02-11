class User < ActiveRecord::Base
  acts_as_authentic
  # attr_accessible :crypted_password, :login, :password_salt, :persistence_token
  attr_accessible :login, :password, :password_confirmation, :role
end
