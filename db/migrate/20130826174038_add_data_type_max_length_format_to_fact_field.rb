class AddDataTypeMaxLengthFormatToFactField < ActiveRecord::Migration
  def change
    add_column :fact_fields, :data_type, :string
    add_column :fact_fields, :max_length, :integer
    add_column :fact_fields, :default_format, :string
  end
end
