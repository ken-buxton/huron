class Dimension < ActiveRecord::Base
  attr_accessible :display_order, :table_display_name, :table_name, :summary_dim, :summary_sql
end
