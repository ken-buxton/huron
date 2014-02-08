class AddSummarySqlToDimension < ActiveRecord::Migration
  def change
    add_column :dimensions, :summary_sql, :string
  end
end
