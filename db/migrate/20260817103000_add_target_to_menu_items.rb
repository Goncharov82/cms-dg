class AddTargetToMenuItems < ActiveRecord::Migration[8.1]
  def change
    add_reference :menu_items, :target, foreign_key: { to_table: :categories }
  end
end
