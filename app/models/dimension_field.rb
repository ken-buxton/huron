class DimensionField < ActiveRecord::Base
  attr_accessible :compare_as, 
    :display_order, 
    :field_display_name, 
    :field_name, 
    :is_primary_key, 
    :table_name,
    :data_type,
    :max_length
end
