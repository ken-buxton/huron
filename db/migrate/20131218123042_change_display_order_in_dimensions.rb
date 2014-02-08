class ChangeDisplayOrderInDimensions < ActiveRecord::Migration
  def up
    change_column :dimensions, :display_order, :string
  end

  def down
    change_column :dimensions, :display_order, :integer
  end
end
