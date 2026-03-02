require "rails_helper"

RSpec.describe OscarsScraper do
  subject(:scraper) { described_class.new(2026) }

  # ── Shared helpers ──────────────────────────────────────────────────────────

  def mock_response(body, success: true)
    r = double("net_http_response")
    allow(r).to receive(:is_a?).and_return(false)
    allow(r).to receive(:is_a?).with(Net::HTTPSuccess).and_return(success)
    allow(r).to receive(:body).and_return(body)
    allow(r).to receive(:code).and_return(success ? "200" : "403")
    r
  end

  def stub_wikipedia(html)
    allow(Net::HTTP).to receive(:start).and_return(mock_response(html))
  end

  # ── HTML fixtures ────────────────────────────────────────────────────────────

  FLAT_HTML = <<~HTML
    <html><body>
    <table class="wikitable defaulttop">
      <tr>
        <td>
          <div><b><a href="/wiki/Best_Picture">Best Picture</a></b></div>
          <ul>
            <li><i>Anora</i></li>
            <li><i>The Brutalist</i></li>
          </ul>
        </td>
        <td>
          <div><b><a href="/wiki/Best_Actor">Best Performance by an Actor in a Leading Role</a></b></div>
          <ul>
            <li>Adrien Brody – <i>The Brutalist</i></li>
            <li>Timothée Chalamet – <i>A Complete Unknown</i></li>
          </ul>
        </td>
        <td>
          <div><b><a href="/wiki/Best_Director">Best Achievement in Directing</a></b></div>
          <ul>
            <li><i>Anora</i> – Sean Baker</li>
            <li><i>The Brutalist</i> – Brady Corbet</li>
          </ul>
        </td>
      </tr>
    </table>
    </body></html>
  HTML

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

  # ── #call ────────────────────────────────────────────────────────────────────

  describe "#call" do
    context "with a flat (2026-style) Wikipedia page" do
      before { stub_wikipedia(FLAT_HTML) }

      it "returns a hash with season and categories keys" do
        expect(scraper.call).to include("season", "categories")
      end

      it "sets the season year" do
        expect(scraper.call.dig("season", "year")).to eq(2026)
      end

      it "includes the year in the season name" do
        expect(scraper.call.dig("season", "name")).to include("2026")
      end

      it "parses all recognised categories" do
        result = scraper.call
        names  = result["categories"].map { |c| c["name"] }
        expect(names).to include("Best Picture", "Best Actor", "Best Director")
      end

      it "marks Best Picture as not having a person" do
        cat = scraper.call["categories"].find { |c| c["name"] == "Best Picture" }
        expect(cat["has_person"]).to be false
      end

      it "parses Best Picture nominees without a person field" do
        cat = scraper.call["categories"].find { |c| c["name"] == "Best Picture" }
        expect(cat["nominees"].map { |n| n["movie"] }).to contain_exactly("Anora", "The Brutalist")
        expect(cat["nominees"].all? { |n| n["person"].nil? }).to be true
      end

      it "marks Best Actor as having a person" do
        cat = scraper.call["categories"].find { |c| c["name"] == "Best Actor" }
        expect(cat["has_person"]).to be true
      end

      it "parses person-first nominees correctly (Best Actor)" do
        cat = scraper.call["categories"].find { |c| c["name"] == "Best Actor" }
        expect(cat["nominees"]).to include(
          hash_including("movie" => "The Brutalist",    "person" => "Adrien Brody"),
          hash_including("movie" => "A Complete Unknown", "person" => "Timothée Chalamet")
        )
      end

      it "parses film-first nominees correctly (Best Director)" do
        cat = scraper.call["categories"].find { |c| c["name"] == "Best Director" }
        expect(cat["nominees"]).to include(
          hash_including("movie" => "Anora",        "person" => "Sean Baker"),
          hash_including("movie" => "The Brutalist", "person" => "Brady Corbet")
        )
      end

      it "returns no errors" do
        scraper.call
        expect(scraper.errors).to be_empty
      end

      it "deduplicates categories with the same name" do
        # Our fixture has each category once; result should not duplicate
        result = scraper.call
        names  = result["categories"].map { |c| c["name"] }
        expect(names).to eq(names.uniq)
      end
    end

    context "with a nested-winner (2025-style) Wikipedia page" do
      before { stub_wikipedia(NESTED_WINNER_HTML) }

      it "parses all nominees including the nested winner" do
        cat = scraper.call["categories"].find { |c| c["name"] == "Best Original Score" }
        expect(cat["nominees"].map { |n| n["movie"] }).to contain_exactly(
          "The Brutalist", "Conclave", "Emilia Pérez"
        )
      end

      it "strips the ‡ winner marker from the person name" do
        cat    = scraper.call["categories"].find { |c| c["name"] == "Best Original Score" }
        winner = cat["nominees"].find { |n| n["movie"] == "The Brutalist" }
        expect(winner["person"]).to eq("Daniel Blumberg")
      end

      it "does not bleed nested nominee text into the winner's person field" do
        cat    = scraper.call["categories"].find { |c| c["name"] == "Best Original Score" }
        winner = cat["nominees"].find { |n| n["movie"] == "The Brutalist" }
        expect(winner["person"]).not_to include("Conclave")
      end
    end

    context "with a song category" do
      before { stub_wikipedia(SONG_HTML) }

      it "uses the quoted song title as the person field" do
        cat = scraper.call["categories"].find { |c| c["name"] == "Best Original Song" }
        expect(cat["nominees"].map { |n| n["person"] }).to contain_exactly("El Mal", "Like a Bird")
      end

      it "uses the film as the movie field" do
        cat = scraper.call["categories"].find { |c| c["name"] == "Best Original Song" }
        expect(cat["nominees"].map { |n| n["movie"] }).to contain_exactly("Emilia Pérez", "Sing Sing")
      end
    end

    context "when Wikipedia returns a non-200 response" do
      before { allow(Net::HTTP).to receive(:start).and_return(mock_response("", success: false)) }

      it "returns nil" do
        expect(scraper.call).to be_nil
      end

      it "records a fetch error" do
        scraper.call
        expect(scraper.errors.first).to match(/failed to fetch/i)
      end
    end

    context "when the nominations table is missing" do
      before { stub_wikipedia("<html><body><p>No table here.</p></body></html>") }

      it "returns nil" do
        expect(scraper.call).to be_nil
      end

      it "records a no-categories error" do
        scraper.call
        expect(scraper.errors.first).to match(/no categories found/i)
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

  # ── TMDB poster fetching ─────────────────────────────────────────────────────

  describe "#fetch_posters (via call)" do
    let(:categories) do
      [
        { "name" => "Best Picture", "has_person" => false,
          "nominees" => [ { "movie" => "Anora" }, { "movie" => "The Brutalist" } ] },
        { "name" => "Best Director", "has_person" => true,
          "nominees" => [ { "movie" => "Anora", "person" => "Sean Baker" } ] }
      ]
    end

    before do
      allow(scraper).to receive(:tmdb_token).and_return("test_token")
      allow(scraper).to receive(:tmdb_fetch_poster) { |movie| "https://img.tmdb.org/#{movie}.jpg" }
    end

    it "sets poster_url on nominees" do
      scraper.send(:fetch_posters, categories)
      expect(categories.first["nominees"].first["poster_url"]).to eq("https://img.tmdb.org/Anora.jpg")
    end

    it "calls TMDB only once per unique movie" do
      expect(scraper).to receive(:tmdb_fetch_poster).exactly(2).times.and_return("url")
      scraper.send(:fetch_posters, categories)
    end

    it "applies the cached poster to the same movie appearing in another category" do
      scraper.send(:fetch_posters, categories)
      bp_anora  = categories.first["nominees"].find { |n| n["movie"] == "Anora" }
      dir_anora = categories.last["nominees"].find  { |n| n["movie"] == "Anora" }
      expect(dir_anora["poster_url"]).to eq(bp_anora["poster_url"])
    end

    it "skips poster_url when TMDB returns nil" do
      allow(scraper).to receive(:tmdb_fetch_poster).and_return(nil)
      scraper.send(:fetch_posters, categories)
      expect(categories.first["nominees"].first["poster_url"]).to be_nil
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
end
