class BackfillMenuItemCategoryTargets < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE menu_items
      SET target_id = categories.id
      FROM categories
      WHERE menu_items.item_type = 1
        AND menu_items.target_id IS NULL
        AND (
          categories.slug = menu_items.slug
          OR LOWER(categories.name) = LOWER(TRIM(REGEXP_REPLACE(COALESCE(menu_items.target_label, ''), '^.*/', '')))
        )
    SQL
  end

  def down
  end
end
