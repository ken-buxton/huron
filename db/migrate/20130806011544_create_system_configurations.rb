class CreateSystemConfigurations < ActiveRecord::Migration
  def change
    create_table :system_configurations do |t|
      t.string :page_title
      t.string :previous_load_status_msg
      t.string :welcome_msg
      t.string :daily_messages

      t.timestamps
    end
  end
end
