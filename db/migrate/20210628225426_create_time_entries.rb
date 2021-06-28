class CreateTimeEntries < ActiveRecord::Migration[6.1]
  def change
    create_table :time_entries do |t|
      t.integer :duration_seconds
      t.datetime :started_at
      t.references :task, null: false, foreign_key: true

      t.timestamps
    end
  end
end
