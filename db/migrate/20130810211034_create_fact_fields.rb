class CreateFactFields < ActiveRecord::Migration
  def change
    create_table :fact_fields do |t|
      t.string :table_name
      t.string :field_name
      t.string :field_display_name
      t.string :display_order
      t.string :field_type
      t.string :dimension
      t.string :fact_type

      t.timestamps
    end
  end
end
