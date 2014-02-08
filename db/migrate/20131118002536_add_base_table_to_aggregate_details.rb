class AddBaseTableToAggregateDetails < ActiveRecord::Migration
  def change
    add_column :aggregate_details, :base_table, :string
  end
end
