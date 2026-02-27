puts "Seeding (#{Rails.env})..."

email    = ENV.fetch("ADMIN_EMAIL", "admin@oscars.com")
password = ENV.fetch("ADMIN_PASSWORD", "password123")
name     = ENV.fetch("ADMIN_NAME", "Admin")

admin = User.find_or_initialize_by(email_address: email)
if admin.new_record?
  admin.update!(display_name: name, password: password, password_confirmation: password, admin: true)
  puts "  Created admin: #{email}"
else
  puts "  Admin already exists: #{email}"
end

puts "Done."
