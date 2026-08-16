require "test_helper"

class PageTest < ActiveSupport::TestCase
  test "generates a slug and stores a draft page" do
    page = Page.create!(title: "О компании", body_html: "<h1>О компании</h1>")

    assert_equal "o-kompanii", page.slug
    assert_predicate page, :draft?
  end
end
