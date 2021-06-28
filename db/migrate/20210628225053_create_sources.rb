class CreateSources < ActiveRecord::Migration[6.1]
  def change
    create_table :sources do |t|
      t.text :name
      t.text :access_token
      t.text :account_id
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
