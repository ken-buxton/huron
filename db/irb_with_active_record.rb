require 'active_record'
require 'yaml'

Dir.glob(File.join(File.dirname(__FILE__), './app/models/*.rb')).each {|f| require f }
dbconfig = YAML::load(File.open('./config/database.yml'))
currenv = ENV["RAILS_ENV"]

if not currenv
  currenv = "development"
end

currdbconfig = dbconfig[currenv]
currdbconfig["database"] = currdbconfig["database"]

ActiveRecord::Base.establish_connection(currdbconfig)
