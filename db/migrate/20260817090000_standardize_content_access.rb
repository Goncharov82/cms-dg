class StandardizeContentAccess < ActiveRecord::Migration[8.1]
  def up
    add_column :articles, :visibility, :string, null: false, default: "public"
    execute "UPDATE categories SET visibility = 'admin' WHERE visibility IN ('hidden', 'private')"
    execute "UPDATE pages SET visibility = 'admin' WHERE visibility IN ('hidden', 'private')"
    execute "UPDATE menu_items SET visibility = 'admin' WHERE visibility IN ('hidden', 'private')"
  end

  def down
    remove_column :articles, :visibility
  end
end
