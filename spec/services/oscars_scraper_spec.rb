RSpec.describe OscarsScraper do
  subject(:scraper) { described_class.new(2026, persist_wikitext: false) }

  # ── Shared helpers ──────────────────────────────────────────────────────────

  def mock_response(body, success: true, code: nil)
    r = double("net_http_response")
    allow(r).to receive(:is_a?).and_return(false)
    allow(r).to receive(:is_a?).with(Net::HTTPSuccess).and_return(success)
    allow(r).to receive(:body).and_return(body)
    allow(r).to receive(:code).and_return(code || (success ? "200" : "403"))
    r
  end

  def stub_wikitext_api(wikitext, success: true, page: "98th_Academy_Awards")
    payload = if success
      { "parse" => { "title" => page, "wikitext" => wikitext } }.to_json
    else
      ""
    end
    html_response = mock_response("<html><body><p>No table</p></body></html>")
    api_response = mock_response(payload, success: success)

    http = instance_double(Net::HTTP)
    allow(Net::HTTP).to receive(:start).with("en.wikipedia.org", 443, anything).and_yield(http)
    allow(http).to receive(:request) do |request|
      if request.path.include?("api.php")
        api_response
      else
        html_response
      end
    end
    allow(Rails.application.credentials).to receive(:tmdb_access_token).and_return(nil)
  end

  def stub_wikitext_then_html(wikitext:, html:, wikitext_ok: true)
    api_body = { "parse" => { "wikitext" => wikitext } }.to_json
    api_response = mock_response(api_body, success: wikitext_ok)
    html_response = mock_response(html)

    http = instance_double(Net::HTTP)
    allow(Net::HTTP).to receive(:start).with("en.wikipedia.org", 443, anything).and_yield(http)
    allow(http).to receive(:request) do |request|
      request.path.include?("api.php") ? api_response : html_response
    end
    allow(Rails.application.credentials).to receive(:tmdb_access_token).and_return(nil)
  end

  # ── HTML fixtures (fallback path) ───────────────────────────────────────────

  FLAT_HTML = <<~HTML
    <html><body>
    <table class="wikitable defaulttop">
      <tr>
        <td>
          <div><b><a href="/wiki/Best_Picture">Best Picture</a></b></div>
          <ul>
            <li><i>Anora</i></li>
            <li><i>The Brutalist</i></li>
            <li><i>A Complete Unknown</i></li>
            <li><i>Conclave</i></li>
            <li><i>Dune: Part Two</i></li>
            <li><i>Emilia Pérez</i></li>
            <li><i>I'm Still Here</i></li>
            <li><i>Nickel Boys</i></li>
            <li><i>The Substance</i></li>
            <li><i>Wicked</i></li>
          </ul>
        </td>
        <td>
          <div><b><a href="/wiki/Best_Actor">Best Performance by an Actor in a Leading Role</a></b></div>
          <ul>
            <li>Adrien Brody – <i>The Brutalist</i></li>
            <li>Timothée Chalamet – <i>A Complete Unknown</i></li>
            <li>Colman Domingo – <i>Sing Sing</i></li>
            <li>Ralph Fiennes – <i>Conclave</i></li>
            <li>Sebastian Stan – <i>The Apprentice</i></li>
          </ul>
        </td>
        <td>
          <div><b><a href="/wiki/Best_Actress">Best Actress in a Leading Role</a></b></div>
          <ul>
            <li>Mikey Madison – <i>Anora</i></li>
            <li>Cynthia Erivo – <i>Wicked</i></li>
            <li>Karla Sofía Gascón – <i>Emilia Pérez</i></li>
            <li>Demién Bichir – <i>A Real Pain</i></li>
            <li>Fernanda Torres – <i>I'm Still Here</i></li>
          </ul>
        </td>
        <td>
          <div><b><a href="/wiki/Best_Supporting_Actor">Best Supporting Actor</a></b></div>
          <ul>
            <li>Kieran Culkin – <i>A Real Pain</i></li>
            <li>Yura Borisov – <i>Anora</i></li>
            <li>Edward Norton – <i>A Complete Unknown</i></li>
            <li>Guy Pearce – <i>The Brutalist</i></li>
            <li>Jeremy Strong – <i>The Apprentice</i></li>
          </ul>
        </td>
        <td>
          <div><b><a href="/wiki/Best_Supporting_Actress">Best Supporting Actress</a></b></div>
          <ul>
            <li>Zoe Saldaña – <i>Emilia Pérez</i></li>
            <li>Monica Barbaro – <i>A Complete Unknown</i></li>
            <li>Ariana Grande – <i>Wicked</i></li>
            <li>Felicity Jones – <i>The Brutalist</i></li>
            <li>Isabella Rossellini – <i>Conclave</i></li>
          </ul>
        </td>
        <td>
          <div><b><a href="/wiki/Best_Director">Best Achievement in Directing</a></b></div>
          <ul>
            <li><i>Anora</i> – Sean Baker</li>
            <li><i>The Brutalist</i> – Brady Corbet</li>
            <li><i>A Complete Unknown</i> – James Mangold</li>
            <li><i>Emilia Pérez</i> – Jacques Audiard</li>
            <li><i>The Substance</i> – Coralie Fargeat</li>
          </ul>
        </td>
      </tr>
    </table>
    </body></html>
  HTML

  # Pad FLAT_HTML-derived parse to satisfy MIN_CATEGORIES by using real fixtures for most tests.

  NESTED_WINNER_HTML = <<~HTML
    <html><body>
    <table class="wikitable defaulttop">
      <tr>
        <td>
          <div><b><a href="/wiki/Best_Score">Best Music (Original Score)</a></b></div>
          <ul>
            <li>
              <b><i>The Brutalist</i> – Daniel Blumberg ‡</b>
              <ul>
                <li><i>Conclave</i> – Volker Bertelmann</li>
                <li><i>Emilia Pérez</i> – Clément Ducol</li>
              </ul>
            </li>
          </ul>
        </td>
      </tr>
    </table>
    </body></html>
  HTML

  SONG_HTML = <<~HTML
    <html><body>
    <table class="wikitable defaulttop">
      <tr>
        <td>
          <div><b><a href="/wiki/Best_Song">Best Music (Original Song)</a></b></div>
          <ul>
            <li>"El Mal" from <i>Emilia Pérez</i> – Clément Ducol</li>
            <li>"Like a Bird" from <i>Sing Sing</i> – Adrian Quesada</li>
          </ul>
        </td>
      </tr>
    </table>
    </body></html>
  HTML

  def fixture_wikitext(name)
    File.read(Rails.root.join("spec/fixtures/wikipedia/#{name}"))
  end

  # ── Wikitext fixtures (primary path) ────────────────────────────────────────

  describe "#parse_and_validate_wikitext" do
    {
      "92nd_awards.wikitext" => { year: 2020, categories: 23 },
      "96th_awards.wikitext" => { year: 2024, categories: 23 },
      "97th_awards.wikitext" => { year: 2025, categories: 23 },
      "98th_awards.wikitext" => { year: 2026, categories: 24 }
    }.each do |file, expected|
      context "with #{file}" do
        subject(:scraper) { described_class.new(expected[:year], persist_wikitext: false) }

        it "parses #{expected[:categories]} categories with no invariant errors" do
          cats, errors = scraper.parse_and_validate_wikitext(fixture_wikitext(file))
          expect(errors).to be_empty
          expect(cats.size).to eq(expected[:categories])
        end
      end
    end

    it "handles 2020-style nbsp dashes and Documentary (Feature) titles" do
      cats, errors = described_class.new(2020, persist_wikitext: false)
        .parse_and_validate_wikitext(fixture_wikitext("92nd_awards.wikitext"))
      expect(errors).to be_empty
      actor = cats.find { |c| c["name"] == "Best Actor" }
      expect(actor["nominees"]).to include(
        hash_including("movie" => "Joker", "person" => "Joaquin Phoenix")
      )
      expect(cats.map { |c| c["name"] }).to include(
        "Best Documentary Feature Film", "Best Documentary Short Film"
      )
    end

    it "parses person-first acting nominees from the 98th fixture" do
      cats, = scraper.parse_and_validate_wikitext(fixture_wikitext("98th_awards.wikitext"))
      actor = cats.find { |c| c["name"] == "Best Actor" }
      expect(actor["nominees"]).to include(
        hash_including("movie" => "Sinners", "person" => "Michael B. Jordan")
      )
    end

    it "parses song titles into the person field" do
      cats, = scraper.parse_and_validate_wikitext(fixture_wikitext("98th_awards.wikitext"))
      song = cats.find { |c| c["name"] == "Best Original Song" }
      expect(song["nominees"]).to include(
        hash_including("movie" => "KPop Demon Hunters", "person" => "Golden")
      )
    end

    it "parses Best Casting (98th)" do
      cats, = scraper.parse_and_validate_wikitext(fixture_wikitext("98th_awards.wikitext"))
      casting = cats.find { |c| c["name"] == "Best Casting" }
      expect(casting["nominees"].map { |n| n["person"] }).to include("Cassandra Kulukundis")
    end

    it "handles {{ill}} film titles in short categories" do
      cats, = scraper.parse_and_validate_wikitext(fixture_wikitext("98th_awards.wikitext"))
      short = cats.find { |c| c["name"] == "Best Live Action Short Film" }
      expect(short["nominees"].map { |n| n["movie"] }).to include("Butcher's Stain")
    end

    it "keeps international feature titles without the submitting country" do
      cats, = scraper.parse_and_validate_wikitext(fixture_wikitext("97th_awards.wikitext"))
      international = cats.find { |c| c["name"] == "Best International Feature Film" }
      expect(international["nominees"].map { |n| n["movie"] }).to include("Flow", "I'm Still Here")
      expect(international["nominees"].map { |n| n["movie"] }).not_to include("Flow (Latvia)")
    end
  end

  describe "#validate_categories" do
    it "rejects too few categories" do
      errors = scraper.send(:validate_categories, [
        { "name" => "Best Picture", "has_person" => false, "nominees" => Array.new(10) { |i| { "movie" => "Film #{i}" } } }
      ])
      expect(errors.first).to match(/expected 20–26 categories/i)
    end

    it "rejects person categories missing person names" do
      cats = Array.new(22) do |i|
        { "name" => "Best Visual Effects", "has_person" => false, "nominees" => [ { "movie" => "Film #{i}" } ] }
      end
      cats[0] = {
        "name" => "Best Actor", "has_person" => true,
        "nominees" => Array.new(5) { |i| { "movie" => "Film #{i}" } }
      }
      errors = scraper.send(:validate_categories, cats)
      expect(errors.join).to match(/Best Actor.*without person/i)
    end
  end

  # ── #call ────────────────────────────────────────────────────────────────────

  describe "#call" do
    context "with real 98th wikitext from the API" do
      before { stub_wikitext_api(fixture_wikitext("98th_awards.wikitext")) }

      it "returns a hash with season and categories keys" do
        expect(scraper.call).to include("season", "categories")
      end

      it "sets the season year" do
        expect(scraper.call.dig("season", "year")).to eq(2026)
      end

      it "includes the year in the season name" do
        expect(scraper.call.dig("season", "name")).to include("2026")
      end

      it "parses all recognised categories via wikitext" do
        result = scraper.call
        names  = result["categories"].map { |c| c["name"] }
        expect(names).to include("Best Picture", "Best Actor", "Best Director", "Best Casting")
        expect(scraper.parse_source).to eq(:wikitext)
      end

      it "marks Best Picture as not having a person" do
        cat = scraper.call["categories"].find { |c| c["name"] == "Best Picture" }
        expect(cat["has_person"]).to be false
      end

      it "parses Best Picture nominees without a person field" do
        cat = scraper.call["categories"].find { |c| c["name"] == "Best Picture" }
        expect(cat["nominees"].map { |n| n["movie"] }).to include("One Battle After Another", "Sinners")
        expect(cat["nominees"].all? { |n| n["person"].nil? }).to be true
      end

      it "parses person-first nominees correctly (Best Actor)" do
        cat = scraper.call["categories"].find { |c| c["name"] == "Best Actor" }
        expect(cat["nominees"]).to include(
          hash_including("movie" => "Sinners", "person" => "Michael B. Jordan")
        )
      end

      it "returns no errors" do
        scraper.call
        expect(scraper.errors).to be_empty
      end
    end

    context "when wikitext is unusable but HTML fallback works" do
      # Build enough HTML categories to pass invariants by repeating craft categories
      # is hard — instead stub parse_wikipedia_page to return a valid payload after
      # wikitext fails validation.
      let(:valid_categories) do
        names = OscarsScraper::CATEGORY_MAPPINGS.values.uniq.first(22)
        names.map.with_index do |name, i|
          has_person = OscarsScraper::PERSON_KEYWORDS.any? { |kw| name.include?(kw) }
          nominee_count = name == "Best Picture" ? 10 : 5
          {
            "name" => name,
            "has_person" => has_person,
            "nominees" => Array.new(nominee_count) do |j|
              nom = { "movie" => "Film #{i}-#{j}" }
              nom["person"] = "Person #{j}" if has_person
              nom
            end
          }
        end
      end

      before do
        stub_wikitext_then_html(wikitext: "===Awards===\nno award category templates here\n", html: FLAT_HTML)
        allow_any_instance_of(OscarsScraper).to receive(:parse_wikipedia_page).and_return(valid_categories)
      end

      it "falls back to HTML and succeeds" do
        result = scraper.call
        expect(result).to be_present
        expect(scraper.parse_source).to eq(:html)
      end
    end

    context "when Wikipedia API returns a non-200 response and HTML also fails" do
      before do
        http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:start).with("en.wikipedia.org", 443, anything).and_yield(http)
        allow(http).to receive(:request).and_return(mock_response("", success: false))
        allow(Rails.application.credentials).to receive(:tmdb_access_token).and_return(nil)
      end

      it "returns nil" do
        expect(scraper.call).to be_nil
      end

      it "records a fetch error" do
        scraper.call
        expect(scraper.errors.join).to match(/failed to fetch/i)
      end
    end

    context "when wikitext has no categories and HTML has no table" do
      before { stub_wikitext_api("<html><body><p>No table here.</p></body></html>") }

      it "returns nil" do
        # API succeeds but body is not useful wikitext; HTML fallback gets same stub path
        # Override HTML to empty table page:
        http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:start).with("en.wikipedia.org", 443, anything).and_yield(http)
        allow(http).to receive(:request) do |request|
          if request.path.include?("api.php")
            mock_response({ "parse" => { "wikitext" => "==Lead==\nNothing." } }.to_json)
          else
            mock_response("<html><body><p>No table here.</p></body></html>")
          end
        end
        allow(Rails.application.credentials).to receive(:tmdb_access_token).and_return(nil)
        expect(scraper.call).to be_nil
      end

      it "records a no-categories or incomplete error" do
        http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:start).with("en.wikipedia.org", 443, anything).and_yield(http)
        allow(http).to receive(:request) do |request|
          if request.path.include?("api.php")
            mock_response({ "parse" => { "wikitext" => "==Lead==\nNothing." } }.to_json)
          else
            mock_response("<html><body><p>No table here.</p></body></html>")
          end
        end
        allow(Rails.application.credentials).to receive(:tmdb_access_token).and_return(nil)
        scraper.call
        expect(scraper.errors.join).to match(/no categories found|parse incomplete/i)
      end

      it "exposes raw_wikitext for repair" do
        http = instance_double(Net::HTTP)
        allow(Net::HTTP).to receive(:start).with("en.wikipedia.org", 443, anything).and_yield(http)
        allow(http).to receive(:request) do |request|
          if request.path.include?("api.php")
            mock_response({ "parse" => { "wikitext" => "==Lead==\nbad markup" } }.to_json)
          else
            mock_response("<html><body><p>No table here.</p></body></html>")
          end
        end
        allow(Rails.application.credentials).to receive(:tmdb_access_token).and_return(nil)
        scraper.call
        expect(scraper.raw_wikitext).to include("bad markup")
      end
    end

    context "when an unexpected exception occurs" do
      before { allow(Net::HTTP).to receive(:start).and_raise(StandardError, "connection reset") }

      it "returns nil" do
        expect(scraper.call).to be_nil
      end

      it "records the exception message" do
        scraper.call
        expect(scraper.errors.first).to include("connection reset")
      end
    end
  end

  # ── HTML parser unit tests (fallback) ───────────────────────────────────────

  describe "#parse_wikipedia_page" do
    it "parses flat HTML nominees" do
      doc = Nokogiri::HTML(FLAT_HTML)
      cats = scraper.send(:parse_wikipedia_page, doc)
      expect(cats.map { |c| c["name"] }).to include("Best Picture", "Best Actor", "Best Director")
    end

    it "parses nested-winner HTML without bleeding nested text" do
      doc = Nokogiri::HTML(NESTED_WINNER_HTML)
      cats = scraper.send(:parse_wikipedia_page, doc)
      cat = cats.find { |c| c["name"] == "Best Original Score" }
      expect(cat["nominees"].map { |n| n["movie"] }).to contain_exactly(
        "The Brutalist", "Conclave", "Emilia Pérez"
      )
      winner = cat["nominees"].find { |n| n["movie"] == "The Brutalist" }
      expect(winner["person"]).to eq("Daniel Blumberg")
      expect(winner["person"]).not_to include("Conclave")
    end

    it "uses the quoted song title as the person field" do
      doc = Nokogiri::HTML(SONG_HTML)
      cats = scraper.send(:parse_wikipedia_page, doc)
      cat = cats.find { |c| c["name"] == "Best Original Song" }
      expect(cat["nominees"].map { |n| n["person"] }).to contain_exactly("El Mal", "Like a Bird")
      expect(cat["nominees"].map { |n| n["movie"] }).to contain_exactly("Emilia Pérez", "Sing Sing")
    end

    it "strips a submitting-country suffix from international titles" do
      html = <<~HTML
        <html><body>
        <table class="wikitable defaulttop">
          <tr>
            <td>
              <div><b><a href="/wiki/Best_International_Feature_Film">Best International Feature Film</a></b></div>
              <ul>
                <li><i>The Secret Agent (Brazil)</i></li>
                <li><i>Birdman or (The Unexpected Virtue of Ignorance) (Mexico)</i></li>
              </ul>
            </td>
          </tr>
        </table>
        </body></html>
      HTML
      doc = Nokogiri::HTML(html)
      cats = scraper.send(:parse_wikipedia_page, doc)
      cat = cats.find { |c| c["name"] == "Best International Feature Film" }
      expect(cat["nominees"].map { |n| n["movie"] }).to contain_exactly(
        "The Secret Agent",
        "Birdman or (The Unexpected Virtue of Ignorance)"
      )
    end
  end

  # ── TMDB poster fetching ─────────────────────────────────────────────────────

  describe "#fetch_movie_metadata (via call)" do
    let(:categories) do
      [
        { "name" => "Best Picture", "has_person" => false,
          "nominees" => [ { "movie" => "Anora" }, { "movie" => "The Brutalist" } ] },
        { "name" => "Best Director", "has_person" => true,
          "nominees" => [ { "movie" => "Anora", "person" => "Sean Baker" } ] }
      ]
    end

    let(:lookup) { instance_double(TmdbMovieLookup) }

    before do
      allow(Rails.application.credentials).to receive(:tmdb_access_token).and_return("test_token")
      allow(TmdbMovieLookup).to receive(:new).and_return(lookup)
      allow(lookup).to receive(:fetch) { |movie|
        { "poster_url" => "https://img.tmdb.org/#{movie}.jpg", "description" => "#{movie} plot", "imdb_url" => "https://www.imdb.com/title/tt#{movie}/" }
      }
      allow(scraper).to receive(:sleep)
    end

    it "sets poster, description, and IMDb URL on nominees" do
      scraper.send(:fetch_movie_metadata, categories)
      nominee = categories.first["nominees"].first
      expect(nominee["poster_url"]).to eq("https://img.tmdb.org/Anora.jpg")
      expect(nominee["description"]).to eq("Anora plot")
      expect(nominee["imdb_url"]).to eq("https://www.imdb.com/title/ttAnora/")
    end

    it "calls TMDB only once per unique movie" do
      expect(lookup).to receive(:fetch).exactly(2).times.and_return({ "poster_url" => "url" })
      scraper.send(:fetch_movie_metadata, categories)
    end

    it "applies the cached metadata to the same movie appearing in another category" do
      scraper.send(:fetch_movie_metadata, categories)
      bp_anora  = categories.first["nominees"].find { |n| n["movie"] == "Anora" }
      dir_anora = categories.last["nominees"].find  { |n| n["movie"] == "Anora" }
      expect(dir_anora["poster_url"]).to eq(bp_anora["poster_url"])
      expect(dir_anora["description"]).to eq(bp_anora["description"])
      expect(dir_anora["imdb_url"]).to eq(bp_anora["imdb_url"])
    end

    it "skips metadata when TMDB returns nil" do
      allow(lookup).to receive(:fetch).and_return(nil)
      scraper.send(:fetch_movie_metadata, categories)
      expect(categories.first["nominees"].first["poster_url"]).to be_nil
      expect(categories.first["nominees"].first["description"]).to be_nil
      expect(categories.first["nominees"].first["imdb_url"]).to be_nil
    end
  end

  # ── #call with TMDB token present ────────────────────────────────────────────

  describe "#call with TMDB enabled" do
    before do
      stub_wikitext_api(fixture_wikitext("98th_awards.wikitext"))
      allow(Rails.application.credentials).to receive(:tmdb_access_token).and_return("tok")
      lookup = instance_double(TmdbMovieLookup, fetch: nil)
      allow(TmdbMovieLookup).to receive(:new).and_return(lookup)
      allow(scraper).to receive(:sleep)
    end

    it "calls fetch_movie_metadata when a token is present" do
      expect(scraper).to receive(:fetch_movie_metadata)
      scraper.call
    end
  end

  # ── #ordinal_number ──────────────────────────────────────────────────────────

  describe "#ordinal_number" do
    {
      1 => "1st", 2 => "2nd", 3 => "3rd", 4 => "4th",
      10 => "10th", 11 => "11th", 12 => "12th", 13 => "13th",
      21 => "21st", 22 => "22nd", 23 => "23rd", 98 => "98th"
    }.each do |n, expected|
      it "returns '#{expected}' for #{n}" do
        expect(scraper.send(:ordinal_number, n)).to eq(expected)
      end
    end
  end

  # ── #clean ───────────────────────────────────────────────────────────────────

  describe "#clean" do
    it "strips Wikipedia citation brackets like [1]" do
      expect(scraper.send(:clean, "text [1] here")).to eq("text here")
    end

    it "strips the ‡ winner symbol" do
      expect(scraper.send(:clean, "Daniel Blumberg ‡")).to eq("Daniel Blumberg")
    end

    it "strips the † symbol" do
      expect(scraper.send(:clean, "Name †")).to eq("Name")
    end

    it "converts non-breaking spaces to regular spaces" do
      expect(scraper.send(:clean, "word\u00a0here")).to eq("word here")
    end

    it "collapses multiple whitespace into single spaces" do
      expect(scraper.send(:clean, "too  many   spaces")).to eq("too many spaces")
    end

    it "strips leading and trailing whitespace" do
      expect(scraper.send(:clean, "  padded  ")).to eq("padded")
    end
  end

  # ── #normalize_category_name ─────────────────────────────────────────────────

  describe "#normalize_category_name" do
    it "returns the original name when no mapping matches" do
      expect(scraper.send(:normalize_category_name, "Unrecognized Award")).to eq("Unrecognized Award")
    end

    it "maps Short Film (Live Action) display names" do
      expect(scraper.send(:normalize_category_name, "Best Short Film (Live Action)")).to eq("Best Live Action Short Film")
    end
  end
end
