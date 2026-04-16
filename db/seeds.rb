admin_password = Rails.application.credentials.seed_admin_password

if admin_password.blank?
  Rails.logger.warn "seed_admin_password is not set in credentials — skipping admin bootstrap"
else
  admin = User.find_or_initialize_by(email_address: "admin@oscars.com")
  new_record = admin.new_record?
  admin.display_name = "Admin"
  admin.admin        = true
  admin.password     = admin_password
  admin.save!
  Rails.logger.info "Admin user #{new_record ? 'created' : 'already existed'}: #{admin.email_address}"
end
