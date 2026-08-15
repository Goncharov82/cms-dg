require "test_helper"

class AdminContentTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email: "content-admin@example.com", password: "a-secure-password", role: :admin)
    post session_path, params: { email: @admin.email, password: "a-secure-password" }
  end

  test "administrator can open content sections" do
    {
      admin_articles_path => "Статьи",
      admin_categories_path => "Категории",
      admin_pages_path => "Страницы",
      admin_site_menu_path => "Меню сайта",
      admin_analytics_path => "Аналитика"
    }.each do |path, heading|
      get path
      assert_response :success
      assert_select "h1", heading
    end
  end

  test "administrator can create an article with seo settings" do
    assert_difference("Article.count") do
      post admin_articles_path, params: {
        submit_action: "draft",
        article: {
          title: "Новая статья", excerpt: "Анонс", body: "Текст",
          seo_title: "SEO-заголовок", meta_description: "Описание",
          allow_indexing: "1", allow_follow: "1", include_in_sitemap: "1"
        }
      }
    end

    assert_redirected_to admin_article_path(Article.last)
    assert_equal "draft", Article.last.status
    assert_equal "novaya-statya", Article.last.slug
    assert_equal "SEO-заголовок", Article.last.seo_title
  end

  test "administrator can open and create a category" do
    get new_admin_category_path
    assert_response :success
    assert_select "h1", "Добавление категории"
    assert_select "button", text: "Сохранить черновик"
    assert_select "button", text: "Опубликовать"

    assert_difference("Category.count") do
      post admin_categories_path, params: {
        submit_action: "draft",
        category: {
          name: "Нейросети", short_description: "Практические материалы",
          description: "Описание категории", visibility: "public",
          articles_sort: "newest", articles_per_page: 12,
          show_description: "1", show_image: "1", use_for_open_graph: "1"
        }
      }
    end

    assert_redirected_to admin_categories_path
    assert_equal "neyroseti", Category.last.slug
    assert_predicate Category.last, :draft?
  end

  test "admin shell has nested articles navigation and theme controls" do
    get admin_root_path
    assert_response :success
    assert_select ".sidebar-group .sidebar-sublink[href='#{admin_articles_path}']", text: /Статьи/
    assert_select "button[aria-label='Включить светлую тему']"
    assert_select "button[aria-label='Включить тёмную тему']"
  end
end
