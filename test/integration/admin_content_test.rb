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

    get admin_categories_path
    assert_select "th[data-column='access']", "Доступ"
    assert_no_match(/\{\d+\s*=>/, response.body)
    assert_select "button.sidebar-collapse-control[data-action='sidebar#toggleCollapsed']", text: "Скрыть меню"
  end

  test "content tables show state icons, entity IDs, and article views" do
    category = Category.create!(name: "Колонки категории", status: :draft)
    article = Article.create!(title: "Колонки статьи", body: "Текст", category: category, status: :published, views_count: 321)
    page = Page.create!(title: "Колонки страницы", body_html: "<p>Текст</p>", status: :published, views_count: 87)
    item = MenuItem.create!(label: "Колонки меню", slug: "columns-menu", item_type: :external, url: "/columns", status: :draft)

    {
      admin_categories_path => [category.id, false],
      admin_pages_path => [page.id, true],
      admin_site_menu_path => [item.id, false]
    }.each do |path, (id, published)|
      get path
      assert_response :success
      assert_select "th[data-column='status']", text: "Состояние"
      assert_select "th[data-column='id']", text: "ID"
      assert_select "td[data-column='id']", text: id.to_s
      assert_select ".state-toggle.state-indicator.#{published ? "is-published" : "is-unpublished"}[data-tooltip]"
      assert_select "th[data-column='status'][data-fixed-column][data-fixed-position='left']"
      assert_select "th[data-column='id'][data-fixed-column][data-fixed-position='right']"
      assert_select "input[data-table-columns-target='checkbox'][value='status']", count: 0
      assert_select "input[data-table-columns-target='checkbox'][value='id']", count: 0
    end

    get admin_pages_path
    assert_select "th[data-column='views'][data-fixed-column][data-fixed-position='right']", text: "Просмотры"
    assert_select "td[data-column='views'] .views-count", text: "87"

    get admin_categories_path
    assert_select "td[data-column='name'].entity-title-cell" do
      assert_select "a.entity-primary-link", text: category.name
      assert_select ".entity-meta .entity-meta-label", text: "Алиас:"
      assert_select ".entity-meta", text: /Алиас:\s*#{Regexp.escape(category.slug)}/
    end

    get admin_site_menu_path
    assert_select "th[data-column='target']", count: 0
    assert_select "th[data-column='url']", count: 0
    assert_select "td[data-column='name'].entity-title-cell" do
      assert_select "a.entity-primary-link", text: item.label
      assert_select ".entity-meta .entity-meta-label", text: "Алиас:"
      assert_select ".entity-meta .entity-meta-label", text: "Внешняя ссылка:"
      assert_select ".entity-meta", text: /Алиас:\s*#{Regexp.escape(item.slug)}/
      assert_select ".entity-meta", text: /Внешняя ссылка:\s*\/columns/
      assert_select ".entity-meta", text: /Привязка:/, count: 0
    end

    get admin_articles_path
    assert_response :success
    assert_select "th[data-column='status']", text: "Состояние"
    assert_select "th[data-column='views'][data-fixed-column][data-fixed-position='right']", text: "Просмотры"
    assert_select "td[data-column='views'] .views-count", text: "321"
    assert_select "td[data-column='id']", text: article.id.to_s
    assert_select ".state-toggle.is-published[aria-label='Опубликовано. Изменить состояние публикации']"
    assert_select "th[data-column='category']", count: 0
    assert_select "td[data-column='title'].entity-title-cell" do
      assert_select "a.entity-primary-link", text: article.title
      assert_select ".entity-meta .entity-meta-label", text: "Алиас:"
      assert_select ".entity-meta .entity-meta-label", text: "Категория:"
      assert_select ".entity-meta", text: /Алиас:\s*#{Regexp.escape(article.slug)}/
      assert_select "a.entity-meta-link[href='#{admin_articles_path(category: category.id)}']", text: category.name
    end
    assert_select "input[data-table-columns-target='checkbox'][value='views']", count: 0
    assert_select "input[data-table-columns-target='checkbox'][value='id']", count: 0
  end

  test "category links open the articles list with a ready filter" do
    selected_category = Category.create!(name: "Фильтруемая категория", status: :published)
    other_category = Category.create!(name: "Другая категория", status: :published)
    selected_article = Article.create!(title: "Статья нужной категории", body: "Текст", category: selected_category, status: :published)
    other_article = Article.create!(title: "Посторонняя статья", body: "Текст", category: other_category, status: :published)

    get admin_articles_path(category: selected_category.id)
    assert_response :success
    assert_select "select[data-table-filters-target='type'] option[value='#{selected_category.id}'][selected]", text: selected_category.name
    assert_select "a.entity-primary-link", text: selected_article.title
    assert_select "a.entity-primary-link", text: other_article.title, count: 0
    assert_select "a.entity-meta-link[href='#{admin_articles_path(category: selected_category.id)}']", text: selected_category.name

    get admin_categories_path
    assert_response :success
    assert_select "a.count-chip-link[href='#{admin_articles_path(category: selected_category.id)}']", text: "1"
  end

  test "administrator can toggle publication from every content table" do
    records = [
      [Article.create!(title: "Переключение статьи", body: "Текст", status: :draft), :toggle_status_admin_article_path],
      [Category.create!(name: "Переключение категории", status: :draft), :toggle_status_admin_category_path],
      [Page.create!(title: "Переключение страницы", body_html: "<p>Текст</p>", status: :draft), :toggle_status_admin_page_path],
      [MenuItem.create!(label: "Переключение меню", item_type: :external, url: "/toggle", status: :draft), :toggle_status_admin_menu_item_path]
    ]

    records.each do |record, route_helper|
      patch public_send(route_helper, record)
      assert_response :redirect
      assert_predicate record.reload, :published?

      patch public_send(route_helper, record)
      assert_response :redirect
      assert_predicate record.reload, :draft?
    end
  end

  test "administrator can open and create a page" do
    get new_admin_page_path
    assert_response :success
    assert_select "h1", "Добавление страницы"
    assert_select "form[action='#{admin_pages_path}']"
    assert_select "[data-page-form-target='htmlEditor']:not([hidden])"
    assert_select "[data-page-form-target='cssEditor'][hidden]"
    assert_select "[data-page-form-target='jsEditor'][hidden]"
    assert_select "textarea[name='page[body_html]'][data-page-form-target='html'][hidden]"
    assert_select "button[data-action='page-form#formatCurrentCode']", text: /Форматировать/

    assert_difference("Page.count") do
      post admin_pages_path, params: {
        submit_action: "published",
        page: { title: "О компании", body_html: "<h1>О компании</h1>", body_css: "", body_js: "", visibility: "public", include_in_sitemap: "1", allow_indexing: "1" }
      }
    end

    assert_redirected_to admin_pages_path
    assert_predicate Page.last, :published?
    assert_equal "o-kompanii", Page.last.slug
  end

  test "administrator can create an article with seo settings" do
    author = Author.create!(name: "Дмитрий Гончаров")
    assert_difference("Article.count") do
      post admin_articles_path, params: {
        submit_action: "draft",
        article: {
          title: "Новая статья", excerpt: "Анонс", body: "Текст",
          seo_title: "SEO-заголовок", meta_description: "Описание",
          allow_indexing: "1", allow_follow: "1", include_in_sitemap: "1",
          author_id: author.id, featured: "1", language: "ru-RU", robots: "index, follow",
          created_at: "2024-02-15T12:00", updated_at: "2025-06-21T13:30"
        }
      }
    end

    assert_redirected_to edit_admin_article_path(Article.last)
    assert_equal "draft", Article.last.status
    assert_equal "novaya-statya", Article.last.slug
    assert_equal "SEO-заголовок", Article.last.seo_title
    assert_equal author, Article.last.author
    assert_predicate Article.last, :featured?
    assert_equal Time.zone.parse("2024-02-15 12:00"), Article.last.created_at
    assert_equal Time.zone.parse("2025-06-21 13:30"), Article.last.updated_at
  end

  test "administrator sees legacy article fields in editor" do
    author = Author.create!(name: "Legacy Author")
    article = Article.create!(title: "Legacy", excerpt: "Вводный текст", body: "", author: author, featured: true, language: "ru-RU", robots: "noarchive")
    get edit_admin_article_path(article)
    assert_response :success
    assert_select "select[name='article[author_id]'] option[selected]", text: author.name
    assert_select "input[name='article[featured]'][type='checkbox']"
    assert_select "input[name='article[language]'][value='ru-RU']"
    assert_select "input[name='article[robots]'][value='noarchive']"
    assert_select "input[name='article[preview_image_upload]'][type='file']"
    assert_select ".editor-tabs button.is-active", text: "Статья"
    assert_select ".editor-tabs button[data-tabs-name='images']", text: "Изображения"
    assert_select ".editor-panel[data-tabs-name='article']:not([hidden])"
    assert_select ".editor-panel[data-tabs-name='images'][hidden]" do
      assert_select "input[name='article[preview_image_upload]'][type='file']"
      assert_select "input[name='article[intro_image_upload]'][type='file']"
      assert_select "input[name='article[fulltext_image_upload]'][type='file']"
      assert_select "input[name='article[main_image_upload]'][type='file']"
    end
    assert_select ".editor-panel[data-tabs-name='seo'][hidden]"
    assert_select "[data-controller='tiptap-editor'].is-resizable [data-tiptap-editor-target='editor']"
    assert_select "textarea[name='article[body]'][data-tiptap-editor-target='source'][hidden]"
    assert_select "[data-tiptap-editor-target='codeEditor'][hidden]"
    assert_select "button[data-action='tiptap-editor#showVisual']", text: "Редактор"
    assert_select "button[data-action='tiptap-editor#showHtml']", text: "HTML"
  end

  test "administrator can open and create a category" do
    get new_admin_category_path
    assert_response :success
    assert_select "h1", "Добавление категории"
    assert_select "[data-controller='tiptap-editor'] textarea[name='category[description]']"
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
    assert_select "a.open-site-link[target='_blank'][rel='noopener'][href='#{root_path}']", text: /Открыть сайт/
    assert_select ".sidebar-footer a.sidebar-link[href='#{admin_settings_path}']", text: /Настройки/
  end

  test "administrator can open settings and manually check editor updates" do
    tiptap_release = {
      installed_version: TiptapReleaseChecker::INSTALLED_VERSION,
      latest_version: TiptapReleaseChecker::INSTALLED_VERSION,
      current: true,
      release_url: TiptapReleaseChecker::RELEASES_URL,
      published_at: Time.current.iso8601,
      checked_at: Time.current,
      error: nil
    }
    codemirror_release = {
      installed_version: CodeMirrorReleaseChecker::INSTALLED_VERSION,
      latest_version: CodeMirrorReleaseChecker::INSTALLED_VERSION,
      current: true,
      release_url: CodeMirrorReleaseChecker::PACKAGE_URL,
      published_at: nil,
      checked_at: Time.current,
      error: nil
    }

    Rails.cache.write(TiptapReleaseChecker::CACHE_KEY, tiptap_release, expires_in: 1.hour)
    Rails.cache.write(CodeMirrorReleaseChecker::CACHE_KEY, codemirror_release, expires_in: 1.hour)
    begin
      get admin_settings_path
      assert_response :success
      assert_select "h1", "Настройки CMS"
      assert_select "input[placeholder='Поиск по настройкам']"
      assert_select ".settings-overview-card", count: 12
      assert_select ".component-update-row", text: /Tiptap Editor/
      assert_select ".component-update-row", text: /CodeMirror/
      assert_select ".update-status.is-current", text: "Актуальная версия", minimum: 1
      assert_select "form[action='#{admin_settings_check_updates_path}'] button", text: "Проверить обновление", count: 2
    ensure
      Rails.cache.delete(TiptapReleaseChecker::CACHE_KEY)
      Rails.cache.delete(CodeMirrorReleaseChecker::CACHE_KEY)
    end
  end

  test "dashboard article links open the editor" do
    article = Article.create!(title: "Материал на дашборде", body: "Текст")

    get admin_root_path

    assert_response :success
    assert_select "a.material-title[href='#{edit_admin_article_path(article)}']", text: article.title
    assert_select "a[href='#{admin_article_path(article)}']", count: 0
  end

  test "article editor has a public preview link" do
    category = Category.create!(name: "Советы редактора", status: :published)
    article = Article.create!(title: "Проверяем просмотр", body: "Текст", status: :published, category: category)

    get edit_admin_article_path(article)

    assert_response :success
    assert_select "a.editor-preview-button[href='#{article.public_path}'][target='_blank'][rel='noopener']", text: /Просмотр/
  end

  test "admin-only content is hidden from editors" do
    public_category = Category.create!(name: "Публичный раздел", visibility: "public")
    admin_category = Category.create!(name: "Служебный раздел", visibility: "admin")
    editor = User.create!(email: "content-editor@example.com", password: "a-secure-password", role: :editor)

    delete session_path
    post session_path, params: { email: editor.email, password: "a-secure-password" }
    get admin_categories_path

    assert_response :success
    assert_select "a", text: public_category.name
    assert_select "a", text: admin_category.name, count: 0

    post admin_categories_path, params: {
      submit_action: "draft",
      category: { name: "Создано редактором", visibility: "admin", articles_per_page: 12 }
    }
    assert_equal "public", Category.find_by!(name: "Создано редактором").visibility
  end

  test "category menu items use root category aliases" do
    root_category = Category.create!(name: "Хостинг", visibility: "public")
    nested_category = Category.create!(name: "VPS", parent: root_category, visibility: "public")

    get new_admin_menu_item_path
    assert_response :success
    assert_select "select[name='menu_item[target_id]'] option", text: "Хостинг / VPS"
    assert_select "label", text: "Адрес ссылки", count: 0
    assert_select ".editor-actions .admin-button", count: 3
    assert_select ".editor-actions .admin-button", text: "Отмена"
    assert_select ".editor-actions .admin-button", text: "Сохранить черновик"
    assert_select ".editor-actions .admin-button", text: "Сохранить"
    assert_select "button", text: "Сформировать", count: 0
    assert_select ".menu-preview", count: 0

    assert_difference("MenuItem.count") do
      post admin_menu_items_path, params: {
        submit_action: "save",
        menu_item: { label: "VPS", slug: "vps", item_type: "category", target_id: nested_category.id, status: "published", visibility: "public" }
      }
    end

    menu_item = MenuItem.last
    assert_equal "/vps", menu_item.url
    assert_equal "Хостинг / VPS", menu_item.target_label
    assert_predicate menu_item, :published?

    patch admin_menu_item_path(menu_item), params: {
      submit_action: "save",
      menu_item: { label: "VPS и серверы", slug: "vps", item_type: "category", target_id: nested_category.id, status: "published", visibility: "public" }
    }
    assert_redirected_to admin_site_menu_path
  end
end
