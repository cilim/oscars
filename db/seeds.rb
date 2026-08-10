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

unless ScoringScheme.exists?(name: "Classic")
  classic = ScoringScheme.create!(name: "Classic")
  PickType.create!(
    scoring_scheme: classic,
    name: "Think will win",
    emoji: "🧠",
    points_on_correct: 5,
    points_on_incorrect: 0,
    display_order: 1,
    color: "#0ea5e9",
    allow_multiple_selections: false
  )
  PickType.create!(
    scoring_scheme: classic,
    name: "Want to win",
    emoji: "❤️",
    points_on_correct: 2,
    points_on_incorrect: 0,
    display_order: 2,
    color: "#8b5cf6",
    allow_multiple_selections: false
  )
end
