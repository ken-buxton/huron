class AddSummaryDimToDimension < ActiveRecord::Migration
  def change
    add_column :dimensions, :summary_dim, :boolean
  end
end
