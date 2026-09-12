class OscarsScraper
  require "net/http"
  require "nokogiri"
  require "json"
  require "fileutils"

  USER_AGENT = "OscarsPool/1.0 (https://github.com/cilim/oscars; season-import scraper)".freeze

  # Maps Wikipedia section titles → canonical category names
  CATEGORY_MAPPINGS = {
    /actor in a leading role/i                      => "Best Actor",
    /actress in a leading role/i                    => "Best Actress",
    /actor in a supporting role/i                   => "Best Supporting Actor",
    /actress in a supporting role/i                 => "Best Supporting Actress",
    /animated feature/i                             => "Best Animated Feature Film",
    /short film \(animated\)|animated short/i       => "Best Animated Short Film",
    /cinematography/i                               => "Best Cinematography",
    /costume design/i                               => "Best Costume Design",
    /directing/i                                    => "Best Director",
    /documentary \(feature\)|documentary feature/i  => "Best Documentary Feature Film",
    /documentary \(short|documentary short/i        => "Best Documentary Short Film",
    /film editing/i                                 => "Best Film Editing",
    /international feature/i                        => "Best International Feature Film",
    /short film \(live action\)|live action short/i => "Best Live Action Short Film",
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

  # Categories that almost always have exactly 5 nominees (ties may push to 6).
  FIVE_NOMINEE_CATEGORIES = [
    "Best Actor", "Best Actress", "Best Supporting Actor", "Best Supporting Actress",
    "Best Director"
  ].freeze

  MIN_CATEGORIES = 20
  MAX_CATEGORIES = 26

  attr_reader :errors, :raw_wikitext, :parse_source

  def initialize(year, persist_wikitext: true)
    @year = year.to_i
    @errors = []
    @raw_wikitext = nil
    @parse_source = nil
    @persist_wikitext = persist_wikitext
  end

  def call
    ceremony = ordinal_number(@year - 1928)
    page_title = "#{ceremony}_Academy_Awards"

    categories = scrape_with_fallback(page_title)

    if categories.nil? || categories.empty?
      if @errors.none? { |e| e.match?(/parse incomplete|Failed to fetch|API error/i) }
        @errors << "No categories found on Wikipedia. The page may not exist yet for #{@year} or its structure has changed."
      end
      if @raw_wikitext.present?
        persist_wikitext_dump! if @persist_wikitext
        dump_hint = @persist_wikitext ? "saved to db/data/#{@year}.wikitext" : "available via scraper.raw_wikitext"
        @errors << "Raw wikitext was captured (#{@raw_wikitext.bytesize} bytes) — #{dump_hint} for manual repair."
      end
      return nil
    end

    persist_wikitext_dump! if @persist_wikitext && @raw_wikitext.present?
    fetch_movie_metadata(categories) if Rails.application.credentials.tmdb_access_token.present?

    {
      "season"     => { "name" => "#{ceremony} Academy Awards (#{@year})", "year" => @year },
      "categories" => categories
    }
  rescue => e
    @errors << "Scraping failed: #{e.message}"
    nil
  end

  # Public for the canary rake task / specs that parse fixtures without HTTP.
  def parse_and_validate_wikitext(wikitext)
    @raw_wikitext = wikitext
    categories = parse_wikitext(wikitext)
    errors = validate_categories(categories)
    [ categories, errors ]
  end

  private

  # ── Fetch + fallback ladder ─────────────────────────────────────────────────

  def scrape_with_fallback(page_title)
    wikitext = fetch_wikitext(page_title)
    @raw_wikitext = wikitext

    if wikitext.present?
      categories = parse_wikitext(wikitext)
      if categories.any? && validate_categories(categories).empty?
        @parse_source = :wikitext
        return categories
      end

      wikitext_errors = validate_categories(categories)
      @errors << "Wikitext parse incomplete (#{categories.size} categories): #{wikitext_errors.join('; ')}" if categories.any?
    end

    html = fetch_html(page_title)
    if html.present?
      categories = parse_wikipedia_page(Nokogiri::HTML(html))
      if categories.any? && validate_categories(categories).empty?
        @parse_source = :html
        @errors.clear
        return categories
      end

      html_errors = validate_categories(categories)
      @errors << "HTML parse incomplete (#{categories.size} categories): #{html_errors.join('; ')}" if categories.any?
    end

    nil
  end

  def fetch_wikitext(page_title)
    uri = URI("https://en.wikipedia.org/w/api.php")
    uri.query = URI.encode_www_form(
      action: "parse",
      page: page_title,
      prop: "wikitext",
      format: "json",
      formatversion: "2"
    )
    response = http_get(uri)
    unless response.is_a?(Net::HTTPSuccess)
      @errors << "Failed to fetch Wikipedia wikitext for #{page_title} (HTTP #{response.code})."
      return nil
    end

    data = JSON.parse(response.body)
    if data["error"]
      @errors << "Wikipedia API error for #{page_title}: #{data.dig('error', 'info') || data['error']}"
      return nil
    end

    data.dig("parse", "wikitext")
  rescue JSON::ParserError => e
    @errors << "Invalid Wikipedia API JSON: #{e.message}"
    nil
  end

  def fetch_html(page_title)
    uri = URI("https://en.wikipedia.org/wiki/#{page_title}")
    response = http_get(uri)
    unless response.is_a?(Net::HTTPSuccess)
      @errors << "Failed to fetch Wikipedia HTML for #{page_title} (HTTP #{response.code})."
      return nil
    end
    response.body
  end

  def http_get(url)
    Net::HTTP.start(url.host, url.port, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
      request = Net::HTTP::Get.new(url)
      request["User-Agent"] = USER_AGENT
      request["Accept"] = "application/json, text/html, */*"
      http.request(request)
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

  def persist_wikitext_dump!
    dir = Rails.root.join("db/data")
    FileUtils.mkdir_p(dir)
    File.write(dir.join("#{@year}.wikitext"), @raw_wikitext)
  rescue => e
    Rails.logger.warn("Could not persist wikitext dump for #{@year}: #{e.message}")
  end

  # ── Invariants ──────────────────────────────────────────────────────────────

  def validate_categories(categories)
    errors = []
    return [ "no categories parsed" ] if categories.nil? || categories.empty?

    count = categories.size
    unless count.between?(MIN_CATEGORIES, MAX_CATEGORIES)
      errors << "expected #{MIN_CATEGORIES}–#{MAX_CATEGORIES} categories, got #{count}"
    end

    names = categories.map { |c| c["name"] }
    dupes = names.group_by(&:itself).select { |_, v| v.size > 1 }.keys
    errors << "duplicate categories: #{dupes.join(', ')}" if dupes.any?

    categories.each do |cat|
      noms = cat["nominees"] || []
      if noms.empty?
        errors << "#{cat['name']}: no nominees"
        next
      end

      if noms.any? { |n| n["movie"].to_s.strip.empty? }
        errors << "#{cat['name']}: nominee missing movie"
      end

      if cat["has_person"] && noms.any? { |n| n["person"].to_s.strip.empty? }
        errors << "#{cat['name']}: person category has nominee without person"
      end

      if cat["name"] == "Best Picture"
        unless noms.size.between?(5, 12)
          errors << "Best Picture: expected 5–12 nominees, got #{noms.size}"
        end
        if cat["has_person"]
          errors << "Best Picture should not be a person category"
        end
      elsif FIVE_NOMINEE_CATEGORIES.include?(cat["name"])
        unless noms.size.between?(4, 6)
          errors << "#{cat['name']}: expected 4–6 nominees, got #{noms.size}"
        end
      end
    end

    errors
  end

  # ── Wikitext parser ─────────────────────────────────────────────────────────

  def parse_wikitext(wikitext)
    text = strip_refs(wikitext.to_s)
    start = text.index("===Awards===") || text.index("==Winners and nominees==") || 0
    rest = text[start..]
    cut = rest.index("===Governors Awards===") ||
          rest.index("==Presenters and performers==") ||
          rest.index("==Ceremony information==") ||
          rest.index("===Films with multiple")
    section = cut ? rest[0...cut] : rest

    categories = []
    section.split(/\{\{[Aa]ward category/).drop(1).each do |part|
      header_end = part.index("}}")
      next unless header_end

      header = part[0...header_end]
      body = part[(header_end + 2)..]

      raw_name = category_name_from_header(header)
      next unless oscar_category?(raw_name)

      cat_name = normalize_category_name(raw_name)
      has_person = person_category?(cat_name)
      nominees = []

      body.each_line do |line|
        next unless line.match?(/^\*+\s+/)

        movie = Movie.normalized_name(extract_movie_from_wikitext(line))
        next if movie.blank?

        nom = { "movie" => movie }
        if has_person
          person = extract_person_from_wikitext(line, movie, cat_name)
          nom["person"] = person if person.present?
        end
        nominees << nom
      end

      next if nominees.empty?
      categories << { "name" => cat_name, "has_person" => has_person, "nominees" => nominees }
    end

    categories.uniq { |c| c["name"] }
  end

  def category_name_from_header(header)
    if header =~ /\[\[(?:[^\]|]+\|)?([^\]]+)\]\]/
      Regexp.last_match(1).strip
    else
      strip_wikitext(header)
    end
  end

  def extract_movie_from_wikitext(line)
    if (m = line.match(/''\[\[(?:([^\]|]+)\|)?([^\]]+)\]\]''/))
      return clean(m[2] || m[1])
    end
    if (m = line.match(/''\{\{ill\|([^|}]+)[^}]*\}\}/))
      return clean(m[1])
    end
    if (m = line.match(/''([^'\[]+)''/))
      return strip_wikitext(m[1])
    end
    nil
  end

  def extract_person_from_wikitext(line, movie, cat_name)
    if cat_name.include?("Song")
      if (m = line.match(/"\{\{ill\|([^|}]+)[^}]*\}\}"/))
        return clean(m[1])
      end
      if (m = line.match(/"\[\[(?:[^\]|]+\|)?([^\]]+)\]\]"/))
        return clean(m[1])
      end
      if (m = line.match(/"([^"]+)"/))
        return strip_wikitext(m[1])
      end
      return nil
    end

    plain = strip_wikitext(line.sub(/^\*+\s*/, ""))
    return nil unless plain.include?(" – ")

    before, after = plain.split(" – ", 2)
    if before.include?(movie)
      after.split(";").first
           .gsub(/\bdirected by\s*/i, "")
           .gsub(/\bas\b.*/, "")
           .gsub(/\b(?:co-)?producers?\b/i, "")
           .gsub(/\bMusic and lyrics by\s*/i, "")
           .gsub(/\bProduction Design:\s*/i, "")
           .strip
           .sub(/,\s*$/, "")
           .strip
           .presence
    else
      before.gsub(/\bas\b.*/, "").strip.presence
    end
  end

  def strip_refs(text)
    text.gsub(/<ref\b[^>]*>.*?<\/ref>/mi, "").gsub(/<ref\b[^>]*\/>/i, "")
  end

  def strip_wikitext(text)
    t = strip_refs(text.to_s.dup)
    t.gsub!(/&nbsp;|&#160;|&#x0*a0;/i, " ")
    t.gsub!(/<small\b[^>]*>.*?<\/small>/mi, "")
    t.gsub!(/\{\{abbr\|[^|]*\|([^}]+)\}\}/i, '\1')
    t.gsub!(/\{\{ill\|([^|}]+)[^}]*\}\}/i, '\1')
    t.gsub!(/\{\{[^}]+\}\}/, "")
    t.gsub!(/\[\[([^\]|]+)\|([^\]]+)\]\]/, '\2')
    t.gsub!(/\[\[([^\]]+)\]\]/, '\1')
    t.gsub!(/'{2,}/, "")
    clean(t)
  end

  # ── HTML parser (fallback) ──────────────────────────────────────────────────
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

    table = doc.at_css("table.wikitable.defaulttop") || doc.at_css("table.wikitable")
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
        movie = Movie.normalized_name(clean(li.at_css("i")&.text.to_s)).presence
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
    text.to_s.gsub(/\[[^\]]+\]/, "").gsub(/[‡†]/, "").gsub(/\u00a0/, " ").gsub(/\s+/, " ").strip
  end

  def oscar_category?(name)
    CATEGORY_MAPPINGS.keys.any? { |pat| name.match?(pat) }
  end

  # ── TMDB movie metadata ───────────────────────────────────────────────────

  def fetch_movie_metadata(categories)
    seen = {}
    lookup = TmdbMovieLookup.new

    categories.each do |cat|
      (cat["nominees"] || []).each do |nom|
        movie = nom["movie"]
        meta = if seen.key?(movie)
          seen[movie]
        else
          result = lookup.fetch(movie)
          seen[movie] = result
          sleep 0.26
          result
        end
        next unless meta

        nom["poster_url"]  = meta["poster_url"]  if meta["poster_url"]
        nom["description"] = meta["description"] if meta["description"]
        nom["imdb_url"]    = meta["imdb_url"]    if meta["imdb_url"]
      end
    end
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
