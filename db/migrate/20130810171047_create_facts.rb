class CreateFacts < ActiveRecord::Migration
  def change
    create_table :facts do |t|
      t.string :table_name
      t.string :table_display_name
      t.integer :display_order

      t.timestamps
    end
  end
end
