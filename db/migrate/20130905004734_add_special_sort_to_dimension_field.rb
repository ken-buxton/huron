class AddSpecialSortToDimensionField < ActiveRecord::Migration
  def change
    add_column :dimension_fields, :special_sort, :string
  end
end
