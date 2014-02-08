class ChangeDisplayOrderInFacts < ActiveRecord::Migration
  def up
    change_column :facts, :display_order, :string
  end

  def down
    change_column :facts, :display_order, :string
  end
end
