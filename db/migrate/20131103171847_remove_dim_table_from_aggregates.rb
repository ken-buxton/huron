class RemoveDimTableFromAggregates < ActiveRecord::Migration
  def up
    remove_column :aggregates, :dim_table_1
    remove_column :aggregates, :dim_table_2
    remove_column :aggregates, :dim_table_3
    remove_column :aggregates, :dim_table_4
    remove_column :aggregates, :dim_table_5
    remove_column :aggregates, :dim_table_6
    remove_column :aggregates, :dim_table_7
    remove_column :aggregates, :dim_table_8
  end

  def down
    add_column :aggregates, :dim_table_8, :string
    add_column :aggregates, :dim_table_7, :string
    add_column :aggregates, :dim_table_6, :string
    add_column :aggregates, :dim_table_5, :string
    add_column :aggregates, :dim_table_4, :string
    add_column :aggregates, :dim_table_3, :string
    add_column :aggregates, :dim_table_2, :string
    add_column :aggregates, :dim_table_1, :string
  end
end
