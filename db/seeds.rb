admin_email = ENV["ADMIN_EMAIL"].to_s.strip
admin_password = ENV["ADMIN_PASSWORD"].to_s

if admin_email.present? && admin_password.present?
  admin = User.find_or_initialize_by(email: admin_email)

  if admin.new_record?
    admin.password = admin_password
    admin.password_confirmation = admin_password
  end

  admin.role = :admin
  admin.save!
  puts "Administrator is ready: #{admin.email}"
else
  puts "Administrator was not created: set ADMIN_EMAIL and ADMIN_PASSWORD."
end

main_menu_categories = [
  "Хостинги и VPS",
  "Обзоры",
  "Софт и сервисы",
  "Нейросети",
  "О сайтах",
  "Советы",
  "Маркетинг"
]

home_item = MenuItem.find_or_initialize_by(slug: "glavnoe")
home_item.update!(
  label: "Главное", item_type: :page, status: :published, visibility: "public",
  menu_name: "main", position: 0, target_label: "Главная страница", target_id: nil, url: "/"
)

main_menu_categories.each_with_index do |category_name, index|
  category = Category.find_by!(name: category_name)
  category.update!(status: :published, parent: nil)
  item = MenuItem.find_or_initialize_by(slug: category.slug)
  item.update!(
    label: category.name, item_type: :category, status: :published, visibility: "public",
    menu_name: "main", position: index + 1, target_category: category, url: category.public_path
  )
end

puts "Main menu is ready: #{MenuItem.where(menu_name: "main").count} items."

author = Author.find_by(email: "info@goncharoff.pro") || Author.find_by(name: "Дмитрий Гончаров")
avatar_path = Rails.root.join("legacy_source/joomla/images/avatar/dmitry_goncharov.jpg")
if author && avatar_path.exist? && !author.avatar.attached?
  author.avatar.attach(io: File.open(avatar_path, "rb"), filename: "dmitry-goncharov.jpg", content_type: "image/jpeg")
  puts "Author avatar is ready: #{author.name}"
end
