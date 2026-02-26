puts "Seeding database..."

# Admin user
admin = User.find_or_create_by!(email_address: "admin@oscars.com") do |u|
  u.display_name = "Admin"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.admin = true
end
puts "  Admin: admin@oscars.com / password123"

# Regular users
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
puts "  Created #{users.count} players (password: password123)"

# Categories
categories_data = [
  { name: "Best Picture", has_person: false },
  { name: "Best Director", has_person: true },
  { name: "Best Actor", has_person: true },
  { name: "Best Actress", has_person: true },
  { name: "Best Supporting Actor", has_person: true },
  { name: "Best Supporting Actress", has_person: true },
  { name: "Best Original Screenplay", has_person: true },
  { name: "Best Adapted Screenplay", has_person: true },
  { name: "Best Animated Feature", has_person: false },
  { name: "Best International Feature", has_person: false },
  { name: "Best Documentary Feature", has_person: false },
  { name: "Best Cinematography", has_person: true },
  { name: "Best Film Editing", has_person: true },
  { name: "Best Original Score", has_person: true },
  { name: "Best Original Song", has_person: false },
  { name: "Best Production Design", has_person: false },
  { name: "Best Costume Design", has_person: true },
  { name: "Best Makeup and Hairstyling", has_person: false },
  { name: "Best Sound", has_person: false },
  { name: "Best Visual Effects", has_person: false },
  { name: "Best Casting", has_person: true }
]

categories = categories_data.map do |data|
  Category.find_or_create_by!(name: data[:name]) do |c|
    c.has_person = data[:has_person]
  end
end
puts "  Created #{categories.count} categories"

# 2025 Season (97th Oscars)
season = Season.find_or_create_by!(year: 2025) do |s|
  s.name = "97th Academy Awards (2025)"
end

# Add main categories to 2025 season
main_2025_categories = [
  "Best Picture", "Best Director", "Best Actor", "Best Actress",
  "Best Supporting Actor", "Best Supporting Actress",
  "Best Original Screenplay", "Best Adapted Screenplay",
  "Best Animated Feature", "Best International Feature",
  "Best Cinematography", "Best Original Score", "Best Original Song",
  "Best Production Design", "Best Costume Design",
  "Best Makeup and Hairstyling", "Best Sound", "Best Visual Effects",
  "Best Film Editing", "Best Documentary Feature"
]

main_2025_categories.each_with_index do |cat_name, i|
  cat = Category.find_by!(name: cat_name)
  SeasonCategory.find_or_create_by!(season: season, category: cat) do |sc|
    sc.position = i
  end
end

# Add nominees for key categories
nominees_data = {
  "Best Picture" => [
    { movie: "Anora" },
    { movie: "The Brutalist" },
    { movie: "A Complete Unknown" },
    { movie: "Conclave" },
    { movie: "Dune: Part Two" },
    { movie: "Emilia Pérez" },
    { movie: "I'm Still Here" },
    { movie: "Nickel Boys" },
    { movie: "The Substance" },
    { movie: "Wicked" }
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
  sc = SeasonCategory.find_by!(season: season, category: cat)
  noms.each do |nom_data|
    Nominee.find_or_create_by!(
      season_category: sc,
      movie_name: nom_data[:movie],
      person_name: nom_data[:person]
    )
  end
end
puts "  Added nominees for #{nominees_data.keys.count} categories"

# Add all users as players
([ admin ] + users).each do |user|
  Player.find_or_create_by!(user: user, season: season)
end
puts "  Added #{season.players.count} players to #{season.name}"

# Add some sample picks for players
season.players.includes(:user).each do |player|
  season.season_categories.includes(:nominees).each do |sc|
    next if sc.nominees.empty?

    Pick.find_or_create_by!(player: player, season_category: sc) do |pick|
      nominees = sc.nominees.to_a
      pick.think_will_win = nominees.sample
      pick.want_to_win = nominees.sample
    end
  end
end
puts "  Generated sample picks for all players"

puts "Done! Sign in at admin@oscars.com / password123"
