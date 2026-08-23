class AddLegacyContentSupport < ActiveRecord::Migration[8.1]
  def change
    create_table :authors do |t|
      t.string :name, null: false
      t.string :email
      t.string :legacy_source
      t.bigint :legacy_id
      t.timestamps
    end
    add_index :authors, %i[legacy_source legacy_id], unique: true

    create_table :media_assets do |t|
      t.string :legacy_source
      t.string :source_path
      t.string :source_url
      t.string :sha256
      t.string :format
      t.bigint :source_byte_size
      t.integer :width
      t.integer :height
      t.string :alt_text
      t.text :caption
      t.timestamps
    end
    add_index :media_assets, %i[legacy_source source_path], unique: true
    add_index :media_assets, :sha256

    create_table :legacy_redirects do |t|
      t.string :legacy_source, null: false
      t.string :old_path, null: false
      t.string :new_path, null: false
      t.integer :http_status, null: false, default: 301
      t.timestamps
    end
    add_index :legacy_redirects, :old_path, unique: true

    change_table :articles, bulk: true do |t|
      t.references :author, foreign_key: true
      t.references :preview_image, foreign_key: { to_table: :media_assets }
      t.references :intro_image, foreign_key: { to_table: :media_assets }
      t.references :fulltext_image, foreign_key: { to_table: :media_assets }
      t.references :main_image, foreign_key: { to_table: :media_assets }
      t.boolean :featured, null: false, default: false
      t.integer :position, null: false, default: 0
      t.string :language
      t.text :meta_keywords
      t.string :robots
      t.string :legacy_source
      t.bigint :legacy_id
      t.string :legacy_url
      t.string :preview_image_alt
      t.text :preview_image_caption
      t.string :intro_image_alt
      t.text :intro_image_caption
      t.string :fulltext_image_alt
      t.text :fulltext_image_caption
      t.string :main_image_alt
      t.text :main_image_caption
    end
    add_index :articles, %i[legacy_source legacy_id], unique: true
    add_index :articles, :legacy_url, unique: true, where: "legacy_url IS NOT NULL"
    add_index :articles, :featured

    change_table :categories, bulk: true do |t|
      t.string :legacy_source
      t.bigint :legacy_id
      t.string :legacy_url
      t.integer :position, null: false, default: 0
      t.string :language
      t.text :meta_keywords
      t.string :robots
    end
    add_index :categories, %i[legacy_source legacy_id], unique: true
  end
end
