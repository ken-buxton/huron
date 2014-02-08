class CreateDimensionFields < ActiveRecord::Migration
  def change
    create_table :dimension_fields do |t|
      t.string :table_name
      t.string :field_name
      t.string :field_display_name
      t.string :display_order
      t.string :compare_as
      t.boolean :is_primary_key

      t.timestamps
    end
  end
end
