require "test_helper"

class AccessControlledTest < ActiveSupport::TestCase
  setup do
    @admin = User.create!(email: "access-admin@example.com", password: "a-secure-password", role: :admin)
    @editor = User.create!(email: "access-editor@example.com", password: "a-secure-password", role: :editor)
  end

  test "public access excludes admin-only content for guests and editors" do
    records_by_model.each do |model, records|
      public_record, admin_record = records

      assert_equal [public_record.id], model.accessible_to(nil).pluck(:id)
      assert_equal [public_record.id], model.accessible_to(@editor).pluck(:id)
      assert_equal [public_record.id, admin_record.id].sort, model.accessible_to(@admin).pluck(:id).sort
      assert_predicate admin_record, :admin_only?
    end
  end

  private

  def records_by_model
    @records_by_model ||= {
      Category => [
        Category.create!(name: "Публичная категория", visibility: "public"),
        Category.create!(name: "Админская категория", visibility: "admin")
      ],
      Article => [
        Article.create!(title: "Публичная статья", body: "Текст", visibility: "public"),
        Article.create!(title: "Админская статья", body: "Текст", visibility: "admin")
      ],
      Page => [
        Page.create!(title: "Публичная страница", body_html: "<p>Текст</p>", visibility: "public"),
        Page.create!(title: "Админская страница", body_html: "<p>Текст</p>", visibility: "admin")
      ],
      MenuItem => [
        MenuItem.create!(label: "Публичный пункт", visibility: "public"),
        MenuItem.create!(label: "Админский пункт", visibility: "admin")
      ]
    }
  end
end
