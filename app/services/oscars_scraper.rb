class OscarsScraper
  require "net/http"
  require "nokogiri"
  require "json"

  # Maps Wikipedia section titles → canonical category names
  CATEGORY_MAPPINGS = {
    /actor in a leading role/i                      => "Best Actor",
    /actress in a leading role/i                    => "Best Actress",
    /actor in a supporting role/i                   => "Best Supporting Actor",
    /actress in a supporting role/i                 => "Best Supporting Actress",
    /animated feature/i                             => "Best Animated Feature Film",
    /animated short/i                               => "Best Animated Short Film",
    /cinematography/i                               => "Best Cinematography",
    /costume design/i                               => "Best Costume Design",
    /directing/i                                    => "Best Director",
    /documentary feature/i                          => "Best Documentary Feature Film",
    /documentary short/i                            => "Best Documentary Short Film",
    /film editing/i                                 => "Best Film Editing",
    /international feature/i                        => "Best International Feature Film",
    /live action short/i                            => "Best Live Action Short Film",
    /makeup and hairstyling/i                       => "Best Makeup and Hairstyling",
    /original score|music \(original score\)/i      => "Best Original Score",
    /original song|music \(original song\)/i        => "Best Original Song",
    /best picture/i                                 => "Best Picture",
    /production design/i                            => "Best Production Design",
    /\bsound\b/i                                    => "Best Sound",
    /visual effects/i                               => "Best Visual Effects",
    /adapted screenplay|writing \(adapted/i         => "Best Adapted Screenplay",
    /original screenplay|writing \(original/i       => "Best Original Screenplay",
    /casting/i                                      => "Best Casting"
  }.freeze

  PERSON_KEYWORDS = %w[Actor Actress Director Casting Score Song Screenplay Cinematography].freeze

  attr_reader :errors

  def initialize(year)
    @year   = year.to_i
    @errors = []
  end

  def call
    ceremony = ordinal_number(@year - 1928)
    url      = URI("https://en.wikipedia.org/wiki/#{ceremony}_Academy_Awards")
    response = http_get(url)

    unless response.is_a?(Net::HTTPSuccess)
      @errors << "Failed to fetch Wikipedia page for the #{ceremony} Academy Awards (HTTP #{response.code})."
      return nil
    end

    doc        = Nokogiri::HTML(response.body)
    categories = parse_wikipedia_page(doc)

    if categories.empty?
      @errors << "No categories found on Wikipedia. The page may not exist yet for #{@year} or its structure has changed."
      return nil
    end

    fetch_posters(categories) if tmdb_token.present?

    {
      "season"     => { "name" => "#{ceremony} Academy Awards (#{@year})", "year" => @year },
      "categories" => categories
    }
  rescue => e
    @errors << "Scraping failed: #{e.message}"
    nil
  end

  private

  # ── Wikipedia fetch ───────────────────────────────────────────────────────

  def http_get(url)
    Net::HTTP.start(url.host, url.port, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
      http.get(url.request_uri)
    end
  end

  def ordinal_number(n)
    suffix = if (11..13).include?(n % 100)
               "th"
             else
               case n % 10
               when 1 then "st"
               when 2 then "nd"
               when 3 then "rd"
               else "th"
               end
             end
    "#{n}#{suffix}"
  end

  # ── Wikipedia parser ──────────────────────────────────────────────────────
  #
  # The 98th Academy Awards Wikipedia page has ONE big table (wikitable defaulttop)
  # where each <td> holds one category. Inside each <td>:
  #   • a <div><b><a>Category Name</a></b></div> header
  #   • a <ul> with <li> items for each nominee
  #
  # Nominee <li> formats:
  #   Person-first (actors, director, cinematography):
  #     Person – <i>Film</i> [as Character]
  #   Film-first (score, screenplay, picture, documentary, etc.):
  #     <i>Film</i> – Person [; extra notes]
  #   Song:
  #     "Song Title" from <i>Film</i> – songwriter info

  def parse_wikipedia_page(doc)
    categories = []

    table = doc.at_css("table.wikitable.defaulttop")
    return categories unless table

    table.css("td").each do |td|
      cat_link = td.at_css("div b a") || td.at_css("div b")
      next unless cat_link

      raw_name = cat_link.text.strip
      next unless oscar_category?(raw_name)

      cat_name = normalize_category_name(raw_name)

      has_person = person_category?(cat_name)
      nominees   = []

      td.css("ul > li").each do |li|
        movie = clean(li.at_css("i")&.text.to_s).presence
        next unless movie

        nom = { "movie" => movie }
        nom["person"] = extract_person(li, movie, cat_name) if has_person
        nom.delete("person") if nom["person"].blank?
        nominees << nom
      end

      next if nominees.empty?
      categories << { "name" => cat_name, "has_person" => has_person, "nominees" => nominees }
    end

    categories.uniq { |c| c["name"] }
  end

  # Determines the "person" field from a nominee <li> element.
  # Two patterns exist:
  #   Film-first:   <i>Film</i> – Person  (score, screenplay, picture)
  #   Person-first: Person – <i>Film</i>  (actors, director, cinematography)
  # Song is a special case: "Title" from <i>Film</i> – songwriter
  def extract_person(li, movie, cat_name)
    # Strip nested <ul> (used on some years to nest other nominees inside the winner's <li>)
    # so their text doesn't bleed into this nominee's person field.
    li_node = li.dup
    li_node.css("ul").each(&:remove)

    if cat_name.include?("Song")
      li_node.text.match(/"([^"]+)"/)&.captures&.first
    else
      full = clean(li_node.text)
      return nil unless full.include?(" – ")

      before, after = full.split(" – ", 2)
      if before.strip.include?(movie)
        # Film-first → person is after the dash; strip trailing notes
        after.split(";").first.gsub(/\bdirected by\s*/i, "").strip
      else
        # Person-first → person is before the dash
        before.strip
      end
    end
  end

  def clean(text)
    text.gsub(/\[[^\]]+\]/, "").gsub(/[‡†]/, "").gsub(/\u00a0/, " ").gsub(/\s+/, " ").strip
  end

  def oscar_category?(name)
    CATEGORY_MAPPINGS.keys.any? { |pat| name.match?(pat) }
  end

  # ── TMDB poster fetch ─────────────────────────────────────────────────────

  def tmdb_token
    Rails.application.credentials.tmdb_access_token
  end

  def fetch_posters(categories)
    seen = {}
    categories.each do |cat|
      (cat["nominees"] || []).each do |nom|
        movie = nom["movie"]
        if seen.key?(movie)
          nom["poster_url"] = seen[movie] if seen[movie]
        else
          url = tmdb_fetch_poster(movie)
          seen[movie] = url
          nom["poster_url"] = url if url
          sleep 0.26
        end
      end
    end
  end

  def tmdb_fetch_poster(movie_name)
    uri     = URI("https://api.themoviedb.org/3/search/movie?query=#{URI.encode_www_form_component(movie_name)}&language=en-US&page=1")
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{tmdb_token}"
    request["Accept"]        = "application/json"

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) { |h| h.request(request) }
    return nil unless response.is_a?(Net::HTTPSuccess)

    results = JSON.parse(response.body)["results"] || []
    path    = results.first&.fetch("poster_path", nil)
    path ? "https://image.tmdb.org/t/p/w500#{path}" : nil
  rescue => e
    Rails.logger.warn "TMDB lookup failed for '#{movie_name}': #{e.message}"
    nil
  end

  # ── Name normalisation ────────────────────────────────────────────────────

  def normalize_category_name(name)
    CATEGORY_MAPPINGS.each { |pattern, normalized| return normalized if name.match?(pattern) }
    name
  end

  def person_category?(name)
    PERSON_KEYWORDS.any? { |kw| name.include?(kw) }
  end
end
