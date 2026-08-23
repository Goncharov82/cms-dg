class AddViewsCountToPages < ActiveRecord::Migration[8.1]
  def change
    add_column :pages, :views_count, :bigint, null: false, default: 0
    add_index :pages, :views_count
  end
end
