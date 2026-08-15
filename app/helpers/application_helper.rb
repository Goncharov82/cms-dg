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
    sliders: ["M4 6h4", "M12 6h8", "M8 4v4", "M4 12h10", "M18 12h2", "M14 10v4", "M4 18h2", "M10 18h10", "M6 16v4"],
    calendar: ["M5 4h14v16H5z", "M8 2v4", "M16 2v4", "M5 9h14"],
    eye: ["M2 12s3.5-6 10-6 10 6 10 6-3.5 6-10 6S2 12 2 12", "M12 9a3 3 0 1 0 0 6 3 3 0 0 0 0-6"],
    users: ["M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8", "M3 21v-2a6 6 0 0 1 12 0v2", "M17 11a3 3 0 1 0 0-6", "M17 15a5 5 0 0 1 4 4v2"],
    clock: ["M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18", "M12 7v5l3 2"],
    save: ["M5 3h12l2 2v16H5z", "M8 3v6h8V3", "M8 15h8v6"],
    desktop: ["M3 4h18v13H3z", "M8 21h8", "M12 17v4"],
    phone: ["M8 2h8v20H8z", "M11 18h2"],
    sun: ["M12 2v2", "M12 20v2", "M4.93 4.93l1.42 1.42", "M17.66 17.66l1.41 1.41", "M2 12h2", "M20 12h2", "M6.34 17.66l-1.41 1.41", "M19.07 4.93l-1.41 1.42", "M12 8a4 4 0 1 0 0 8 4 4 0 0 0 0-8"],
    moon: ["M20.5 14.2A8.5 8.5 0 0 1 9.8 3.5 8.5 8.5 0 1 0 20.5 14.2z"]
  }.freeze

  def admin_icon(name, class_name: "admin-icon")
    paths = ADMIN_ICON_PATHS.fetch(name.to_sym)
    content = safe_join(paths.map { |path| tag.path(d: path) })
    tag.svg(content, class: class_name, viewBox: "0 0 24 24", fill: "none", stroke: "currentColor", "stroke-width": 1.8, "stroke-linecap": "round", "stroke-linejoin": "round", "aria-hidden": true)
  end

  def admin_display_name(user)
    user.admin? ? "Администратор" : user.email.split("@").first.tr("._-", " ").titleize
  end
end
