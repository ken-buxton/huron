class Aggregate < ActiveRecord::Base
  attr_accessible :aggregate_display_name, :aggregate_table_name, :creation_sql, :dim_table_1, :dim_table_2, :dim_table_3, :dim_table_4, :dim_table_5, :dim_table_6, :dim_table_7, :dim_table_8, :fact_table_name, :search_order, :update_sql
end
