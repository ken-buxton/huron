class CreateIndices < ActiveRecord::Migration
  def change
    create_table :indices do |t|
      t.string :group_name
      t.string :create_order
      t.string :creation_sql

      t.timestamps
    end
  end
end
