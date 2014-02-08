class CreateReports < ActiveRecord::Migration
  def change
    create_table :reports do |t|
      t.string :report_name
      t.string :user_id
      t.string :private
      t.string :report_group
      t.text :dims
      t.text :rows
      t.text :columns
      t.text :facts

      t.timestamps
    end
  end
end
