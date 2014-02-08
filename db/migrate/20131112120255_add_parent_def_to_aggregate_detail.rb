class AddParentDefToAggregateDetail < ActiveRecord::Migration
  def change
    add_column :aggregate_details, :parent_def, :string
  end
end
