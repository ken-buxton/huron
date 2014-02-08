class SystemConfiguration < ActiveRecord::Base
  attr_accessible :daily_messages, :page_title, :previous_load_status_msg, :welcome_msg
end
