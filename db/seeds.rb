puts "Seeding (#{Rails.env})..."

# ── Production seed ───────────────────────────────────────
# Creates the admin user from env vars and imports YAML data.
# Runs on every startup but is fully idempotent.
if Rails.env.production?
  # Admin user
  email    = ENV.fetch("ADMIN_EMAIL")
  password = ENV.fetch("ADMIN_PASSWORD")
  name     = ENV.fetch("ADMIN_NAME", "Admin")

  admin = User.find_or_initialize_by(email_address: email)
  if admin.new_record?
    admin.update!(display_name: name, password: password, password_confirmation: password, admin: true)
    puts "  Created admin: #{email}"
  else
    puts "  Admin already exists: #{email}"
  end

  # Import all YAML data files that have not been imported yet
  Dir[Rails.root.join("db/data/*.yml")].sort.each do |file|
    data        = YAML.safe_load_file(file, permitted_classes: [Symbol])
    season_data = data["season"]

    if Season.exists?(year: season_data["year"])
      puts "  Season #{season_data['year']} already imported — skipping"
      next
    end

    puts "  Importing #{File.basename(file)}..."
    ActiveRecord::Base.transaction do
      season = Season.create!(name: season_data["name"], year: season_data["year"])

      data["categories"].each_with_index do |cat_data, position|
        category = Category.find_or_create_by!(name: cat_data["name"]) do |c|
          c.has_person = cat_data["has_person"]
        end
        sc = SeasonCategory.create!(season: season, category: category, position: position)

        (cat_data["nominees"] || []).each do |nom_data|
          Nominee.create!(
            season_category: sc,
            movie_name:      nom_data["movie"],
            person_name:     nom_data["person"],
            poster_url:      nom_data["poster_url"]
          )
        end
      end

      puts "    Imported: #{season.name}"
    end
  end

  puts "Done."
  exit 0
end

# ── Development seed ──────────────────────────────────────
# Fake users, categories, nominees, picks for local testing.

admin = User.find_or_create_by!(email_address: "admin@oscars.com") do |u|
  u.display_name = "Admin"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.admin = true
end
puts "  Admin: admin@oscars.com / password123"

players_data = [
  { email: "alice@example.com", name: "Alice" },
  { email: "bob@example.com", name: "Bob" },
  { email: "charlie@example.com", name: "Charlie" },
  { email: "diana@example.com", name: "Diana" }
]

users = players_data.map do |data|
  User.find_or_create_by!(email_address: data[:email]) do |u|
    u.display_name = data[:name]
    u.password = "password123"
    u.password_confirmation = "password123"
  end
end
puts "  Created #{users.count} players"

categories_data = [
  { name: "Best Picture",            has_person: false },
  { name: "Best Director",           has_person: true },
  { name: "Best Actor",              has_person: true },
  { name: "Best Actress",            has_person: true },
  { name: "Best Supporting Actor",   has_person: true },
  { name: "Best Supporting Actress", has_person: true },
  { name: "Best Original Screenplay",has_person: true },
  { name: "Best Adapted Screenplay", has_person: true },
  { name: "Best Animated Feature",   has_person: false },
  { name: "Best International Feature", has_person: false },
  { name: "Best Documentary Feature",has_person: false },
  { name: "Best Cinematography",     has_person: true },
  { name: "Best Film Editing",       has_person: true },
  { name: "Best Original Score",     has_person: true },
  { name: "Best Original Song",      has_person: false },
  { name: "Best Production Design",  has_person: false },
  { name: "Best Costume Design",     has_person: true },
  { name: "Best Makeup and Hairstyling", has_person: false },
  { name: "Best Sound",              has_person: false },
  { name: "Best Visual Effects",     has_person: false }
]

categories = categories_data.map do |data|
  Category.find_or_create_by!(name: data[:name]) { |c| c.has_person = data[:has_person] }
end
puts "  #{categories.count} categories"

season = Season.find_or_create_by!(year: 2025) { |s| s.name = "97th Academy Awards (2025)" }

categories_data.map { |d| d[:name] }.each_with_index do |cat_name, i|
  cat = Category.find_by!(name: cat_name)
  SeasonCategory.find_or_create_by!(season: season, category: cat) { |sc| sc.position = i }
end

nominees_data = {
  "Best Picture" => [
    { movie: "Anora" }, { movie: "The Brutalist" }, { movie: "A Complete Unknown" },
    { movie: "Conclave" }, { movie: "Emilia Pérez" }, { movie: "I'm Still Here" },
    { movie: "Nickel Boys" }, { movie: "The Substance" }, { movie: "Wicked" }
  ],
  "Best Director" => [
    { movie: "Anora", person: "Sean Baker" },
    { movie: "The Brutalist", person: "Brady Corbet" },
    { movie: "A Complete Unknown", person: "James Mangold" },
    { movie: "Emilia Pérez", person: "Jacques Audiard" },
    { movie: "The Substance", person: "Coralie Fargeat" }
  ],
  "Best Actor" => [
    { movie: "The Brutalist", person: "Adrien Brody" },
    { movie: "A Complete Unknown", person: "Timothée Chalamet" },
    { movie: "Sing Sing", person: "Colman Domingo" },
    { movie: "The Apprentice", person: "Sebastian Stan" },
    { movie: "A Real Pain", person: "Jesse Eisenberg" }
  ],
  "Best Actress" => [
    { movie: "Emilia Pérez", person: "Karla Sofía Gascón" },
    { movie: "Wicked", person: "Cynthia Erivo" },
    { movie: "Anora", person: "Mikey Madison" },
    { movie: "The Substance", person: "Demi Moore" },
    { movie: "I'm Still Here", person: "Fernanda Torres" }
  ],
  "Best Supporting Actor" => [
    { movie: "A Complete Unknown", person: "Edward Norton" },
    { movie: "A Real Pain", person: "Kieran Culkin" },
    { movie: "Anora", person: "Yura Borisov" },
    { movie: "The Brutalist", person: "Guy Pearce" },
    { movie: "Conclave", person: "Stanley Tucci" }
  ],
  "Best Supporting Actress" => [
    { movie: "Emilia Pérez", person: "Zoe Saldaña" },
    { movie: "Wicked", person: "Ariana Grande" },
    { movie: "The Brutalist", person: "Felicity Jones" },
    { movie: "Conclave", person: "Isabella Rossellini" },
    { movie: "A Complete Unknown", person: "Monica Barbaro" }
  ]
}

nominees_data.each do |cat_name, noms|
  cat = Category.find_by!(name: cat_name)
  sc  = SeasonCategory.find_by!(season: season, category: cat)
  noms.each do |n|
    Nominee.find_or_create_by!(season_category: sc, movie_name: n[:movie], person_name: n[:person])
  end
end
puts "  Nominees seeded"

([ admin ] + users).each { |u| Player.find_or_create_by!(user: u, season: season) }

season.players.includes(:user).each do |player|
  season.season_categories.includes(:nominees).each do |sc|
    next if sc.nominees.empty?
    Pick.find_or_create_by!(player: player, season_category: sc) do |pick|
      nominees = sc.nominees.to_a
      pick.think_will_win = nominees.sample
      pick.want_to_win    = nominees.sample
    end
  end
end
puts "  Sample picks generated"

puts "Done! Sign in at admin@oscars.com / password123"
