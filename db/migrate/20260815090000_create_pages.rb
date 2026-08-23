class CreatePages < ActiveRecord::Migration[8.1]
  def change
    create_table :pages do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :body_html, null: false
      t.text :body_css
      t.text :body_js
      t.integer :status, null: false, default: 0
      t.string :visibility, null: false, default: "public"
      t.string :seo_title
      t.text :meta_description
      t.string :canonical_url
      t.boolean :include_in_sitemap, null: false, default: true
      t.boolean :allow_indexing, null: false, default: true
      t.timestamps
    end

    add_index :pages, :slug, unique: true
    add_index :pages, :status
  end
end
