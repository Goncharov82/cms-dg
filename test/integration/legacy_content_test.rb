require "test_helper"

class LegacyContentTest < ActionDispatch::IntegrationTest
  test "published public article is served at preserved legacy URL" do
    article = Article.create!(title: "Legacy route", body: "<p>Content</p>", status: :published, legacy_url: "/old/category/legacy-route", views_count: 12)
    get article.legacy_url
    assert_response :success
    assert_select "h1", article.title
    assert_equal 13, article.reload.views_count
  end

  test "admin-only legacy article is not public" do
    article = Article.create!(title: "Private legacy", body: "Private", status: :published, visibility: "admin", legacy_url: "/private-legacy")
    get article.legacy_url
    assert_response :not_found
  end

  test "category and article open at alias-based public paths" do
    parent = Category.create!(name: "Блог", status: :published, visibility: "public")
    category = Category.create!(name: "Обзоры сервисов", parent: parent, status: :published, visibility: "public")
    article = Article.create!(title: "Полезный сервис", body: "Описание", status: :published, visibility: "public", category: category)

    assert_equal "/obzory-servisov", category.public_path
    assert_equal "/obzory-servisov/poleznyy-servis", article.public_path

    get category.public_path
    assert_response :success
    assert_select "a[href='#{article.public_path}']", text: article.title

    get article.public_path
    assert_response :success
    assert_select "h1", article.title
    assert_select ".public-article-page__layout > .public-category__sidebar", 1
    assert_select ".public-sidebar-ad[href*='timeweb_rotation']", 1
    assert_select ".public-sidebar-ad[href*='marketorro_rotation']", 1
    assert_select ".public-latest", 1
  end

  test "article places image before title and shows CMS author metadata" do
    author = Author.create!(name: "Автор сайта", email: "author@example.test")
    author.avatar.attach(io: StringIO.new("avatar-image"), filename: "avatar.jpg", content_type: "image/jpeg")
    category = Category.create!(name: "Обзоры", status: :published, visibility: "public")
    image = MediaAsset.new(legacy_source: "test", source_path: "images/main.webp", sha256: "d" * 64)
    image.file.attach(io: StringIO.new("main-image"), filename: "main.webp", content_type: "image/webp")
    image.save!
    article = Article.create!(title: "Материал с автором", body: "Текст", status: :published, visibility: "public", category: category, author: author, main_image: image, published_at: Time.zone.local(2026, 8, 19), views_count: 41)

    get article.public_path
    assert_response :success
    assert_select ".public-article-main-image + .public-article__content", 1
    assert_select ".public-article-meta", text: /Обзоры.*19\.08\.2026.*42/m
    assert_select ".public-article-author img[alt='Автор сайта'][src='#{author_avatar_path(author)}']", 1
    assert_select ".public-article-author strong", text: "Автор сайта"

    get author_avatar_path(author)
    assert_response :success
    assert_equal "image/jpeg", response.media_type
  end

  test "category template paginates articles and renders independent advertising blocks" do
    category = Category.create!(name: "Шаблон категории", slug: "category-template", status: :published, visibility: "public")
    9.times do |index|
      Article.create!(title: "Материал #{index + 1}", body: "Описание", status: :published, visibility: "public", category: category, published_at: index.days.ago)
    end

    get category.public_path
    assert_response :success
    assert_select ".public-category__articles .public-card", 8
    assert_select ".public-sidebar-ad[href*='timeweb_rotation']", 1
    assert_select ".public-sidebar-ad[href*='marketorro_rotation']", 1
    assert_select ".public-pagination a", { href: "#{category.public_path}?page=2" }, 1

    get "#{category.public_path}?page=2"
    assert_response :success
    assert_select ".public-category__articles .public-card", 1
    assert_select ".public-pagination a.is-active", text: "2"
  end

  test "article HTML keeps formatting and repairs imported media URLs" do
    asset = MediaAsset.new(legacy_source: "test", source_path: "images/example.webp", sha256: "a" * 64)
    asset.file.attach(io: StringIO.new("example-image"), filename: "example.webp", content_type: "image/webp")
    asset.save!
    article = Article.create!(title: "Форматированный материал", body: %(<h2>Раздел</h2><p><strong>Текст</strong></p><img src="//media/#{asset.id}/example.webp">), status: :published)

    get article.public_path
    assert_response :success
    assert_select ".public-article-body h2", text: "Раздел"
    assert_select ".public-article-body strong", text: "Текст"
    assert_select ".public-article-body img[src='#{asset.public_path}']"
  end

  test "media files are served inline without an Active Storage catch-all conflict" do
    asset = MediaAsset.new(legacy_source: "test", source_path: "images/test.webp")
    asset.file.attach(io: StringIO.new("fake-webp"), filename: "test.webp", content_type: "image/webp")
    asset.save!

    get asset.public_path
    assert_response :success
    assert_equal "image/webp", response.media_type
    assert_equal "fake-webp", response.body
  end

  test "blog image paths are unique by content and reuse exact duplicates" do
    first = MediaAsset.new(legacy_source: "test", source_path: "one/photo.webp", sha256: "b" * 64)
    first.file.attach(io: StringIO.new("same-image"), filename: "photo.webp", content_type: "image/webp")
    first.save!
    duplicate = MediaAsset.new(legacy_source: "test", source_path: "two/copy.webp", sha256: first.sha256)
    duplicate.file.attach(first.file.blob)
    duplicate.save!
    different = MediaAsset.new(legacy_source: "test", source_path: "three/photo.webp", sha256: "c" * 64)
    different.file.attach(io: StringIO.new("different-image"), filename: "photo.webp", content_type: "image/webp")
    different.save!

    assert_match %r{\A/images/blog/photo-b{16}\.webp\z}, first.public_path
    assert_equal first.public_path, duplicate.public_path
    assert_not_equal first.public_path, different.public_path
  end

  test "current year variable is rendered from server time across CMS entities" do
    travel_to Time.zone.local(2027, 1, 2, 12, 0, 0) do
      category = Category.create!(name: "Обзоры {YYYY}", slug: "reviews", description: "Материалы за {YYYY}", status: :published)
      article = Article.create!(
        title: "Лучшие сервисы в {MONTH_PRED} {YYYY}", slug: "best-services", excerpt: "Подборка {YYYY}",
        body: "<h2>Рейтинг {YYYY}</h2>", seo_title: "SEO {YYYY}", meta_description: "Описание {YYYY}",
        category: category, status: :published
      )
      page = Page.create!(title: "О проекте {YYYY}", slug: "about", body_html: "<p>Год {YYYY}</p>")
      menu_item = MenuItem.create!(label: "Лучшее {YYYY}", slug: "best", item_type: :external, url: "/best")

      get article.public_path
      assert_response :success
      assert_select "title", text: "SEO 2027"
      assert_select 'meta[name="description"][content="Описание 2027"]'
      assert_select "h1", text: "Лучшие сервисы в январе 2027"
      assert_select ".public-article-body h2", text: "Рейтинг 2027"

      assert_equal "Обзоры 2027", category.rendered_name
      assert_equal "Материалы за 2027", category.rendered_description
      assert_equal "О проекте 2027", page.rendered_title
      assert_equal "<p>Год 2027</p>", page.rendered_body_html
      assert_equal "Лучшее 2027", menu_item.rendered_label
    end
  end


  test "month variable uses the Russian prepositional case" do
    travel_to Time.zone.local(2027, 2, 1, 12, 0, 0) do
      assert_equal "в феврале 2027", ContentVariables.render("в {MONTH_PRED} {YYYY}")
    end
  end
end
