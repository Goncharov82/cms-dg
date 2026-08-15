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

ActiveRecord::Schema[8.1].define(version: 2026_08_15_072000) do
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
    t.text "body", null: false
    t.string "canonical_url"
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.text "excerpt"
    t.boolean "include_in_sitemap", default: true, null: false
    t.text "meta_description"
    t.datetime "published_at"
    t.string "schema_type", default: "Article", null: false
    t.string "seo_title"
    t.string "slug"
    t.integer "status", default: 0, null: false
    t.string "title", null: false
    t.string "twitter_card", default: "summary_large_image", null: false
    t.datetime "updated_at", null: false
    t.boolean "use_article_image_for_og", default: true, null: false
    t.boolean "use_seo_for_og", default: true, null: false
    t.index ["category_id"], name: "index_articles_on_category_id"
    t.index ["published_at"], name: "index_articles_on_published_at"
    t.index ["slug"], name: "index_articles_on_slug", unique: true
    t.index ["status"], name: "index_articles_on_status"
  end

  create_table "categories", force: :cascade do |t|
    t.integer "articles_per_page", default: 12, null: false
    t.string "articles_sort", default: "newest", null: false
    t.string "canonical_url"
    t.datetime "created_at", null: false
    t.text "description"
    t.text "meta_description"
    t.string "name", null: false
    t.bigint "parent_id"
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
    t.index ["parent_id"], name: "index_categories_on_parent_id"
    t.index ["slug"], name: "index_categories_on_slug", unique: true
    t.index ["status"], name: "index_categories_on_status"
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
    t.string "target_label"
    t.datetime "updated_at", null: false
    t.string "url"
    t.string "visibility", default: "public", null: false
    t.index ["menu_name", "position"], name: "index_menu_items_on_menu_name_and_position"
    t.index ["slug"], name: "index_menu_items_on_slug", unique: true
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
  add_foreign_key "articles", "categories"
  add_foreign_key "categories", "categories", column: "parent_id"
end
