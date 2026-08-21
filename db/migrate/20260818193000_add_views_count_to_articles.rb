class AddViewsCountToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :views_count, :bigint, null: false, default: 0
    add_index :articles, :views_count
  end
end
