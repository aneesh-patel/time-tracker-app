class CreateWorkspaces < ActiveRecord::Migration[6.1]
  def change
    create_table :workspaces do |t|
      t.text :original_id
      t.text :source_name
      t.references :source, null: false, foreign_key: true

      t.timestamps
    end
  end
end
