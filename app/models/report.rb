class Report < ActiveRecord::Base
  attr_accessible :columns, :dims, :facts, :private, :report_group, :report_name, :rows, :user_id
end
