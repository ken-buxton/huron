class FactField < ActiveRecord::Base
  attr_accessible :dimension, 
    :display_order, 
    :fact_type, 
    :field_display_name, 
    :field_name, 
    :field_type, 
    :table_name,
    :data_type,
    :max_length,
    :default_format
end
