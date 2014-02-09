class ChangeSummarySqlInDimensions < ActiveRecord::Migration
  def up
    change_column :dimensions, :summary_sql, :text
  end

  def down
    change_column :dimensions, :summary_sql, :string
  end
end
