class CreateAggregateDetails < ActiveRecord::Migration
  def change
    create_table :aggregate_details do |t|
      t.string :aggregate_table_name
      t.string :agg_dim_table
      t.string :order

      t.timestamps
    end
  end
end
