class AddDataTypeMaxLengthToDimensionField < ActiveRecord::Migration
  def change
    add_column :dimension_fields, :data_type, :string
    add_column :dimension_fields, :max_length, :integer
  end
end
