class CreateMenuItems < ActiveRecord::Migration[8.1]
  def change
    create_table :menu_items do |t|
      t.string :label, null: false
      t.string :slug, null: false
      t.integer :item_type, null: false, default: 0
      t.string :target_label
      t.string :url
      t.text :description
      t.integer :status, null: false, default: 0
      t.string :visibility, null: false, default: "public"
      t.string :menu_name, null: false, default: "main"
      t.string :parent_label
      t.integer :position, null: false, default: 0
      t.boolean :open_new_tab, null: false, default: false
      t.boolean :nofollow, null: false, default: false
      t.boolean :hide_mobile, null: false, default: false
      t.timestamps
    end
    add_index :menu_items, :slug, unique: true
    add_index :menu_items, [:menu_name, :position]
  end
end
