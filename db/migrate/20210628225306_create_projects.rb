class CreateProjects < ActiveRecord::Migration[6.1]
  def change
    create_table :projects do |t|
      t.text :original_id
      t.text :name
      t.datetime :due_date
      t.datetime :start_date
      t.references :workspace, null: false, foreign_key: true

      t.timestamps
    end
  end
end
