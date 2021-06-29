class AddOriginalIdToTasks < ActiveRecord::Migration[6.1]
  def change
    add_column :tasks, :original_id, :text
  end
end
