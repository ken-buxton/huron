class AggregateDetail < ActiveRecord::Base
  attr_accessible :agg_dim_table, :aggregate_table_name, :order, :parent_def
end
