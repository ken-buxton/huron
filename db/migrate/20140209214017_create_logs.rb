class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.datetime :log_when
      t.text :log_what

      t.timestamps
    end
  end
end
