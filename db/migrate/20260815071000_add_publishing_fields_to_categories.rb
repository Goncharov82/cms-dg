class AddPublishingFieldsToCategories < ActiveRecord::Migration[8.1]
  def change
    add_column :categories, :slug, :string
    add_reference :categories, :parent, foreign_key: { to_table: :categories }
    add_column :categories, :short_description, :text
    add_column :categories, :status, :integer, null: false, default: 0
    add_column :categories, :visibility, :string, null: false, default: "public"
    add_column :categories, :articles_sort, :string, null: false, default: "newest"
    add_column :categories, :articles_per_page, :integer, null: false, default: 12
    add_column :categories, :show_description, :boolean, null: false, default: true
    add_column :categories, :show_image, :boolean, null: false, default: true
    add_column :categories, :use_for_open_graph, :boolean, null: false, default: true
    add_column :categories, :seo_title, :string
    add_column :categories, :meta_description, :text
    add_column :categories, :canonical_url, :string

    add_index :categories, :slug, unique: true
    add_index :categories, :status
  end
end
