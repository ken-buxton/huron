class CreateDimensions < ActiveRecord::Migration
  def change
    create_table :dimensions do |t|
      t.string :table_name
      t.string :table_display_name
      t.integer :display_order

      t.timestamps
    end
  end
end
