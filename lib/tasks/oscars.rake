namespace :oscars do
  desc "Import a season from a YAML file. Usage: rails oscars:import[2026]"
  task :import, [ :year ] => :environment do |_t, args|
    year = args[:year] || raise("Usage: rails oscars:import[YEAR]")
    file = Rails.root.join("db/data/#{year}.yml")

    unless File.exist?(file)
      abort "File not found: #{file}\nAvailable files: #{Dir[Rails.root.join('db/data/*.yml')].map { |f| File.basename(f, '.yml') }.join(', ')}"
    end

    data = YAML.safe_load_file(file, permitted_classes: [ Symbol ])
    import_season(data)
  end

  desc "Scrape Oscar nominations from oscars.org and save to YAML. Usage: rails oscars:scrape[2027]"
  task :scrape, [ :year ] => :environment do |_t, args|
    year = args[:year] || raise("Usage: rails oscars:scrape[YEAR]")

    require "net/http"
    require "nokogiri"

    url = URI("https://www.oscars.org/oscars/ceremonies/#{year}")
    puts "Fetching #{url}..."

    response = Net::HTTP.get_response(url)
    unless response.is_a?(Net::HTTPSuccess)
      abort "Failed to fetch page (HTTP #{response.code}). The page may not be available yet or may block automated requests.\n" \
            "You can try manually creating the YAML file at db/data/#{year}.yml instead."
    end

    doc = Nokogiri::HTML(response.body)
    categories = parse_oscars_page(doc)

    if categories.empty?
      abort "No categories found. The page structure may have changed.\n" \
            "You can manually create the YAML file at db/data/#{year}.yml instead."
    end

    ceremony_number = doc.at_css("h1")&.text&.strip || "#{year} Academy Awards"

    output = {
      "season" => {
        "name" => "#{ceremony_number} (#{year})",
        "year" => year.to_i
      },
      "categories" => categories
    }

    outfile = Rails.root.join("db/data/#{year}.yml")
    File.write(outfile, output.to_yaml)
    puts "Saved #{categories.length} categories to #{outfile}"
    puts "Review the file, then import with: rails oscars:import[#{year}]"
  end

  desc "List available YAML data files"
  task list: :environment do
    files = Dir[Rails.root.join("db/data/*.yml")].sort
    if files.empty?
      puts "No data files found in db/data/"
    else
      puts "Available data files:"
      files.each do |f|
        data = YAML.safe_load_file(f, permitted_classes: [ Symbol ])
        season = data["season"]
        cats = data["categories"]&.length || 0
        noms = data["categories"]&.sum { |c| c["nominees"]&.length || 0 } || 0
        puts "  #{File.basename(f, '.yml')} - #{season['name']} (#{cats} categories, #{noms} nominees)"
      end
    end
  end

  private

  def import_season(data)
    season_data = data["season"]
    categories_data = data["categories"]

    ActiveRecord::Base.transaction do
      season = Season.find_or_create_by!(year: season_data["year"]) do |s|
        s.name = season_data["name"]
      end
      puts "Season: #{season.name} (id: #{season.id})"

      categories_data.each_with_index do |cat_data, position|
        category = Category.find_or_create_by!(name: cat_data["name"]) do |c|
          c.has_person = cat_data["has_person"]
        end

        sc = SeasonCategory.find_or_create_by!(season: season, category: category) do |s|
          s.position = position
        end

        nominees = cat_data["nominees"] || []
        nominees.each do |nom_data|
          Nominee.find_or_create_by!(
            season_category: sc,
            movie_name: nom_data["movie"],
            person_name: nom_data["person"]
          )
        end

        puts "  #{category.name}: #{nominees.length} nominees"
      end

      puts "Imported #{categories_data.length} categories with nominees."
    end
  end

  def parse_oscars_page(doc)
    categories = []

    # The oscars.org page typically structures categories in sections
    # This parser handles common patterns - may need adjustment if the site changes
    doc.css(".awards-result, .view-grouping, .category-wrapper, .field--name-field-award-categories > .field__item").each do |section|
      cat_name = section.at_css(".awards-result__category, .view-grouping-header, h3, h2")&.text&.strip
      next unless cat_name.present?

      cat_name = normalize_category_name(cat_name)
      has_person = person_category?(cat_name)
      nominees = []

      section.css(".awards-result__nominee, .views-row, .nominee-wrapper, li").each do |nom_el|
        movie = nom_el.at_css(".awards-result__film, .nominee-film, .film-title, em, i")&.text&.strip
        person = nom_el.at_css(".awards-result__recipient, .nominee-name, .person-name, strong, b")&.text&.strip

        if movie.present?
          nom = { "movie" => movie }
          nom["person"] = person if person.present? && has_person
          nominees << nom
        end
      end

      next if nominees.empty?

      categories << {
        "name" => cat_name,
        "has_person" => has_person,
        "nominees" => nominees
      }
    end

    categories
  end

  def normalize_category_name(name)
    mappings = {
      /actor in a leading role/i => "Best Actor",
      /actress in a leading role/i => "Best Actress",
      /actor in a supporting role/i => "Best Supporting Actor",
      /actress in a supporting role/i => "Best Supporting Actress",
      /animated feature/i => "Best Animated Feature Film",
      /animated short/i => "Best Animated Short Film",
      /cinematography/i => "Best Cinematography",
      /costume design/i => "Best Costume Design",
      /directing/i => "Best Director",
      /documentary feature/i => "Best Documentary Feature Film",
      /documentary short/i => "Best Documentary Short Film",
      /film editing/i => "Best Film Editing",
      /international feature/i => "Best International Feature Film",
      /live action short/i => "Best Live Action Short Film",
      /makeup and hairstyling/i => "Best Makeup and Hairstyling",
      /original score|music \(original score\)/i => "Best Original Score",
      /original song|music \(original song\)/i => "Best Original Song",
      /best picture/i => "Best Picture",
      /production design/i => "Best Production Design",
      /sound/i => "Best Sound",
      /visual effects/i => "Best Visual Effects",
      /adapted screenplay|writing \(adapted/i => "Best Adapted Screenplay",
      /original screenplay|writing \(original/i => "Best Original Screenplay",
      /casting/i => "Best Casting"
    }

    mappings.each do |pattern, normalized|
      return normalized if name.match?(pattern)
    end

    name
  end

  def person_category?(name)
    %w[
      Actor Actress Director Casting Score Song Screenplay Cinematography
    ].any? { |keyword| name.include?(keyword) }
  end
end
