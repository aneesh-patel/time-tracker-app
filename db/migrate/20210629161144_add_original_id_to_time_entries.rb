class AddOriginalIdToTimeEntries < ActiveRecord::Migration[6.1]
  def change
    add_column :time_entries, :original_id, :text
  end
end
