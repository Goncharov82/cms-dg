class AddSeoFieldsToArticles < ActiveRecord::Migration[8.1]
  def change
    add_column :articles, :slug, :string
    add_column :articles, :seo_title, :string
    add_column :articles, :meta_description, :text
    add_column :articles, :canonical_url, :string
    add_column :articles, :allow_indexing, :boolean, null: false, default: true
    add_column :articles, :allow_follow, :boolean, null: false, default: true
    add_column :articles, :include_in_sitemap, :boolean, null: false, default: true
    add_column :articles, :schema_type, :string, null: false, default: "Article"
    add_column :articles, :use_seo_for_og, :boolean, null: false, default: true
    add_column :articles, :use_article_image_for_og, :boolean, null: false, default: true
    add_column :articles, :twitter_card, :string, null: false, default: "summary_large_image"

    add_index :articles, :slug, unique: true
  end
end
