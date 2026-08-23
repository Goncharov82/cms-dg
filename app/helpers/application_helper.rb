module ApplicationHelper
  ADMIN_ICON_PATHS = {
    dashboard: ["M3 11.5 12 4l9 7.5", "M5 10v10h5v-6h4v6h5V10"],
    folder: ["M3 6.5h6l2 2h10v10.5H3z"],
    articles: ["M5 3h14v18H5z", "M8 7h8", "M8 11h8", "M8 15h5"],
    page: ["M6 3h8l4 4v14H6z", "M14 3v5h5", "M9 13h6", "M9 17h4"],
    link: ["M10 13a5 5 0 0 0 7.1.1l2-2a5 5 0 0 0-7.1-7.1l-1.1 1.1", "M14 11a5 5 0 0 0-7.1-.1l-2 2A5 5 0 0 0 12 20l1.1-1.1"],
    menu: ["M4 6h16", "M4 12h16", "M4 18h16"],
    image: ["M4 4h16v16H4z", "M8.5 10a1.5 1.5 0 1 0 0-3 1.5 1.5 0 0 0 0 3", "m5 17 4-4 3 3 2-2 5 5"],
    chart: ["M5 20V10", "M12 20V4", "M19 20v-7"],
    settings: ["M12.22 2h-.44a2 2 0 0 0-2 2v.18a2 2 0 0 1-1 1.73l-.43.25a2 2 0 0 1-2 0l-.15-.08a2 2 0 0 0-2.73.73l-.22.38a2 2 0 0 0 .73 2.73l.15.09a2 2 0 0 1 1 1.74v.5a2 2 0 0 1-1 1.74l-.15.09a2 2 0 0 0-.73 2.73l.22.38a2 2 0 0 0 2.73.73l.15-.08a2 2 0 0 1 2 0l.43.25a2 2 0 0 1 1 1.73V20a2 2 0 0 0 2 2h.44a2 2 0 0 0 2-2v-.18a2 2 0 0 1 1-1.73l.43-.25a2 2 0 0 1 2 0l.15.08a2 2 0 0 0 2.73-.73l.22-.38a2 2 0 0 0-.73-2.73l-.15-.09a2 2 0 0 1-1-1.74v-.5a2 2 0 0 1 1-1.74l.15-.09a2 2 0 0 0 .73-2.73l-.22-.38a2 2 0 0 0-2.73-.73l-.15.08a2 2 0 0 1-2 0l-.43-.25a2 2 0 0 1-1-1.73V4a2 2 0 0 0-2-2z", "M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6"],
    chevron_down: ["m7 10 5 5 5-5"],
    chevron_right: ["m9 6 6 6-6 6"],
    plus: ["M12 5v14", "M5 12h14"],
    upload: ["M12 16V4", "m7 9 5-5 5 5", "M5 16v4h14v-4"],
    dots: ["M12 5.5v.01", "M12 12v.01", "M12 18.5v.01"],
    close: ["m6 6 12 12", "m18 6-12 12"],
    logout: ["M10 5H5v14h5", "M14 8l4 4-4 4", "M18 12H9"],
    edit: ["M4 20h4l11-11-4-4L4 16z", "m13-13 4 4"],
    trash: ["M4 7h16", "M9 7V4h6v3", "M7 7l1 14h8l1-14"],
    search: ["M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14", "m16 16 5 5"],
    back: ["m15 18-6-6 6-6"],
    check: ["m5 12 4 4L19 6"],
    check_circle: ["M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20", "m7.5 12 3 3 6-6"],
    x_circle: ["M12 22a10 10 0 1 0 0-20 10 10 0 0 0 0 20", "m8.5 8.5 7 7", "m15.5 8.5-7 7"],
    sliders: ["M4 6h4", "M12 6h8", "M8 4v4", "M4 12h10", "M18 12h2", "M14 10v4", "M4 18h2", "M10 18h10", "M6 16v4"],
    calendar: ["M5 4h14v16H5z", "M8 2v4", "M16 2v4", "M5 9h14"],
    eye: ["M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12", "M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6"],
    users: ["M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8", "M3 21v-2a6 6 0 0 1 12 0v2", "M17 11a3 3 0 1 0 0-6", "M17 15a5 5 0 0 1 4 4v2"],
    user: ["M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8", "M4 21a8 8 0 0 1 16 0"],
    bell: ["M18 8a6 6 0 0 0-12 0c0 7-3 7-3 9h18c0-2-3-2-3-9", "M10 21h4"],
    puzzle: ["M8 3h3a2 2 0 1 1 4 0h3v5h3a2 2 0 1 1 0 4h-3v9h-5v-3a2 2 0 1 0-4 0v3H3v-5h3a2 2 0 1 0 0-4H3V8h5z"],
    shield: ["M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"],
    code: ["m8 9-3 3 3 3", "m16 9 3 3-3 3", "m14 5-4 14"],
    brush: ["m14.5 4.5 5 5L9 20H4v-5z", "m12 7 5 5", "M4 20c0-2 1-4 4-5"],
    clock: ["M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18", "M12 7v5l3 2"],
    save: ["M5 3h12l2 2v16H5z", "M8 3v6h8V3", "M8 15h8v6"],
    desktop: ["M3 4h18v13H3z", "M8 21h8", "M12 17v4"],
    phone: ["M8 2h8v20H8z", "M11 18h2"],
    sun: ["M12 2v2", "M12 20v2", "M4.93 4.93l1.42 1.42", "M17.66 17.66l1.41 1.41", "M2 12h2", "M20 12h2", "M6.34 17.66l-1.41 1.41", "M19.07 4.93l-1.41 1.42", "M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8"],
    moon: ["M20.5 14.2A8.5 8.5 0 0 1 9.8 3.5 8.5 8.5 0 1 0 20.5 14.2z"],
    external: ["M14 4h6v6", "M20 4 11 13", "M18 13v6H5V6h6"]
  }.freeze

  def admin_icon(name, class_name: "admin-icon")
    paths = ADMIN_ICON_PATHS.fetch(name.to_sym)
    content = safe_join(paths.map { |path| tag.path(d: path) })
    tag.svg(content, class: class_name, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": 1.8, "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": true)
  end

  def admin_display_name(user)
    user.admin? ? "Дмитрий Гончаров" : user.email.split("@").first.tr("._-", " ").titleize
  end

  def admin_access_label(record)
    record.visibility == "admin" ? "Админский" : "Публичный"
  end

  def admin_access_options
    [["Публичный", "public"]].tap do |options|
      options << ["Админский", "admin"] if current_user&.admin?
    end
  end

  def admin_menu_item_binding(item)
    type = {
      "page" => "Страница",
      "category" => "Категория",
      "article" => "Статья",
      "external" => "Внешняя ссылка"
    }.fetch(item.item_type)
    target = item.target_label.presence || item.url.presence || "Не выбрано"
    safe_join([tag.span("#{type}:", class: "entity-meta-label"), " #{target}"])
  end

  def admin_state_indicator(record)
    published = record.published?
    label = published ? "Опубликовано" : "Не опубликовано"
    icon = admin_icon(published ? :check_circle : :x_circle)
    changed_at = if published && record.respond_to?(:published_at) && record.published_at.present?
      record.published_at
    else
      record.updated_at
    end
    tooltip = if published
      "Опубликовано\nИзменено: #{I18n.l(changed_at, format: "%d.%m.%Y, %H:%M")}\nСнять с публикации"
    else
      "Не опубликовано\nОпубликовать"
    end
    path = public_send("toggle_status_admin_#{record.model_name.singular}_path", record)

    button_to path,
      method: :patch,
      class: "state-toggle state-indicator #{published ? "is-published" : "is-unpublished"}",
      title: tooltip.lines.first.strip,
      aria: { label: "#{label}. Изменить состояние публикации" },
      data: {
        controller: "tooltip",
        action: "mouseenter->tooltip#show mouseleave->tooltip#hide focus->tooltip#show blur->tooltip#hide",
        tooltip: tooltip
      } do
        icon
      end
  end

  def public_article_card_image(article)
    [article.preview_image, article.intro_image, article.main_image].compact.find { |asset| asset.file.attached? }
  end

  def public_main_menu_items
    @public_main_menu_items ||= MenuItem.published
      .publicly_accessible
      .where(menu_name: "main")
      .order(:position, :created_at)
  end

  def public_menu_item_url(item)
    return item.url if item.url.present?
    return item.target_category.public_path if item.category? && item.target_category.present?

    "/#{item.slug}"
  end

  def public_menu_item_link_options(item)
    rel = []
    rel << "nofollow" if item.nofollow?
    rel.concat(%w[noopener noreferrer]) if item.open_new_tab?

    { target: ("_blank" if item.open_new_tab?), rel: rel.presence&.join(" ") }.compact
  end

  def admin_pagination_pages(current_page, total_pages)
    return (1..total_pages).to_a if total_pages <= 7

    pages = [1, total_pages, current_page - 1, current_page, current_page + 1]
      .select { |page| page.between?(1, total_pages) }
      .uniq
      .sort

    pages.each_cons(2).flat_map { |left, right| right - left > 1 ? [left, :ellipsis] : [left] } + [pages.last]
  end

  def admin_collection_page_path(page)
    url_for(request.query_parameters.merge(page: page, per_page: @per_page))
  end
end
