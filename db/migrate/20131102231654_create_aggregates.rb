class CreateAggregates < ActiveRecord::Migration
  def change
    create_table :aggregates do |t|
      t.string :aggregate_table_name
      t.string :aggregate_display_name
      t.string :fact_table_name
      t.string :search_order
      t.string :dim_table_1
      t.string :dim_table_2
      t.string :dim_table_3
      t.string :dim_table_4
      t.string :dim_table_5
      t.string :dim_table_6
      t.string :dim_table_7
      t.string :dim_table_8
      t.string :creation_sql
      t.string :update_sql

      t.timestamps
    end
  end
end
