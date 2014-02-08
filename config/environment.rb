# Load the rails application
require File.expand_path('../application', __FILE__)

# Add to force to production environment
#ENV['RAILS_ENV'] ||= 'production'

# Initialize the rails application
Huron::Application.initialize!
