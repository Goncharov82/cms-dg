# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_18_194500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "articles", force: :cascade do |t|
    t.boolean "allow_follow", default: true, null: false
    t.boolean "allow_indexing", default: true, null: false
    t.bigint "author_id"
    t.text "body", null: false
    t.string "canonical_url"
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.text "excerpt"
    t.boolean "featured", default: false, null: false
    t.string "fulltext_image_alt"
    t.text "fulltext_image_caption"
    t.bigint "fulltext_image_id"
    t.boolean "include_in_sitemap", default: true, null: false
    t.string "intro_image_alt"
    t.text "intro_image_caption"
    t.bigint "intro_image_id"
    t.string "language"
    t.bigint "legacy_id"
    t.string "legacy_source"
    t.string "legacy_url"
    t.string "main_image_alt"
    t.text "main_image_caption"
    t.bigint "main_image_id"
    t.text "meta_description"
    t.text "meta_keywords"
    t.integer "position", default: 0, null: false
    t.string "preview_image_alt"
    t.text "preview_image_caption"
    t.bigint "preview_image_id"
    t.datetime "published_at"
    t.string "robots"
    t.string "schema_type", default: "Article", null: false
    t.string "seo_title"
    t.string "slug"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.string "twitter_card", default: "summary_large_image", null: false
    t.datetime "updated_at", null: false
    t.boolean "use_article_image_for_og", default: true, null: false
    t.boolean "use_seo_for_og", default: true, null: false
    t.bigint "views_count", default: 0, null: false
    t.string "visibility", default: "public", null: false
    t.index ["author_id"], name: "index_articles_on_author_id"
    t.index ["category_id"], name: "index_articles_on_category_id"
    t.index ["featured"], name: "index_articles_on_featured"
    t.index ["fulltext_image_id"], name: "index_articles_on_fulltext_image_id"
    t.index ["intro_image_id"], name: "index_articles_on_intro_image_id"
    t.index ["legacy_source", "legacy_id"], name: "index_articles_on_legacy_source_and_legacy_id", unique: true
    t.index ["legacy_url"], name: "index_articles_on_legacy_url", unique: true, where: "(legacy_url IS NOT NULL)"
    t.index ["main_image_id"], name: "index_articles_on_main_image_id"
    t.index ["preview_image_id"], name: "index_articles_on_preview_image_id"
    t.index ["published_at"], name: "index_articles_on_published_at"
    t.index ["slug"], name: "index_articles_on_slug", unique: true
    t.index ["status"], name: "index_articles_on_status"
    t.index ["views_count"], name: "index_articles_on_views_count"
  end

  create_table "authors", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email"
    t.bigint "legacy_id"
    t.string "legacy_source"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["legacy_source", "legacy_id"], name: "index_authors_on_legacy_source_and_legacy_id", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.integer "articles_per_page", default: 12, null: false
    t.string "articles_sort", default: "newest", null: false
    t.string "canonical_url"
    t.datetime "created_at", null: false
    t.text "description"
    t.string "language"
    t.bigint "legacy_id"
    t.string "legacy_source"
    t.string "legacy_url"
    t.text "meta_description"
    t.text "meta_keywords"
    t.string "name", null: false
    t.bigint "parent_id"
    t.integer "position", default: 0, null: false
    t.string "robots"
    t.string "seo_title"
    t.text "short_description"
    t.boolean "show_description", default: true, null: false
    t.boolean "show_image", default: true, null: false
    t.string "slug"
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.boolean "use_for_open_graph", default: true, null: false
    t.string "visibility", default: "public", null: false
    t.index "lower((name)::text)", name: "index_categories_on_lower_name", unique: true
    t.index ["legacy_source", "legacy_id"], name: "index_categories_on_legacy_source_and_legacy_id", unique: true
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
    t.index ["status"], name: "index_categories_on_status"
  end

  create_table "legacy_redirects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "http_status", default: 301, null: false
    t.string "legacy_source", null: false
    t.string "new_path", null: false
    t.string "old_path", null: false
    t.datetime "updated_at", null: false
    t.index ["old_path"], name: "index_legacy_redirects_on_old_path", unique: true
  end

  create_table "media_assets", force: :cascade do |t|
    t.string "alt_text"
    t.text "caption"
    t.datetime "created_at", null: false
    t.string "format"
    t.integer "height"
    t.string "legacy_source"
    t.string "sha256"
    t.bigint "source_byte_size"
    t.string "source_path"
    t.string "source_url"
    t.datetime "updated_at", null: false
    t.integer "width"
    t.index ["legacy_source", "source_path"], name: "index_media_assets_on_legacy_source_and_source_path", unique: true
    t.index ["sha256"], name: "index_media_assets_on_sha256"
  end

  create_table "menu_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "hide_mobile", default: false, null: false
    t.integer "item_type", default: 0, null: false
    t.string "label", null: false
    t.string "menu_name", default: "main", null: false
    t.boolean "nofollow", default: false, null: false
    t.boolean "open_new_tab", default: false, null: false
    t.string "parent_label"
    t.integer "position", default: 0, null: false
    t.string "slug", null: false
    t.integer "status", default: 0, null: false
    t.bigint "target_id"
    t.string "target_label"
    t.datetime "updated_at", null: false
    t.string "url"
    t.string "visibility", default: "public", null: false
    t.index ["menu_name", "position"], name: "index_menu_items_on_menu_name_and_position"
    t.index ["slug"], name: "index_menu_items_on_slug", unique: true
    t.index ["target_id"], name: "index_menu_items_on_target_id"
  end

  create_table "pages", force: :cascade do |t|
    t.boolean "allow_indexing", default: true, null: false
    t.text "body_css"
    t.text "body_html", null: false
    t.text "body_js"
    t.string "canonical_url"
    t.datetime "created_at", null: false
    t.boolean "include_in_sitemap", default: true, null: false
    t.text "meta_description"
    t.string "seo_title"
    t.string "slug", null: false
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "views_count", default: 0, null: false
    t.string "visibility", default: "public", null: false
    t.index ["slug"], name: "index_pages_on_slug", unique: true
    t.index ["status"], name: "index_pages_on_status"
    t.index ["views_count"], name: "index_pages_on_views_count"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "password_digest", null: false
    t.integer "role", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index "lower((email)::text)", name: "index_users_on_lower_email", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "articles", "authors"
  add_foreign_key "articles", "categories"
  add_foreign_key "articles", "media_assets", column: "fulltext_image_id"
  add_foreign_key "articles", "media_assets", column: "intro_image_id"
  add_foreign_key "articles", "media_assets", column: "main_image_id"
  add_foreign_key "articles", "media_assets", column: "preview_image_id"
  add_foreign_key "categories", "categories", column: "parent_id"
  add_foreign_key "menu_items", "categories", column: "target_id"
end
