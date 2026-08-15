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
