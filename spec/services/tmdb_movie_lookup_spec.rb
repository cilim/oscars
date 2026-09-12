require "net/http"
require "json"
require "openssl"

RSpec.describe TmdbMovieLookup do
  subject(:lookup) { described_class.new(access_token: "tok") }

  def mock_response(body, success: true)
    r = double("net_http_response")
    allow(r).to receive(:is_a?).and_return(false)
    allow(r).to receive(:is_a?).with(Net::HTTPSuccess).and_return(success)
    allow(r).to receive(:body).and_return(body)
    r
  end

  def stub_tmdb(search_body:, details_body: nil, details_by_id: nil, search_success: true, details_success: true)
    search_response = mock_response(search_body, success: search_success)
    details_response = details_body ? mock_response(details_body, success: details_success) : nil
    details_responses = (details_by_id || {}).transform_values { |body|
      mock_response(body.to_json, success: details_success)
    }

    allow(Net::HTTP).to receive(:start).with("api.themoviedb.org", 443, anything) do |*_args, **_opts, &blk|
      http = double("net_http")
      allow(http).to receive(:request) do |request|
        path = request.path
        if path.include?("/search/movie")
          search_response
        elsif (id = path[%r{/movie/(\d+)}, 1]) && details_responses.key?(id.to_i)
          details_responses[id.to_i]
        else
          details_response
        end
      end
      blk.call(http)
    end
  end

  describe "#fetch" do
    it "returns poster, description, and IMDb URL from search + details" do
      stub_tmdb(
        search_body: { "results" => [ {
          "id" => 11,
          "poster_path" => "/abc.jpg",
          "overview" => "A short overview."
        } ] }.to_json,
        details_body: {
          "overview" => "The full plot synopsis.",
          "imdb_id" => "tt0076759",
          "poster_path" => "/abc.jpg"
        }.to_json
      )

      expect(lookup.fetch("Star Wars")).to eq(
        "poster_url" => "https://image.tmdb.org/t/p/w500/abc.jpg",
        "description" => "The full plot synopsis.",
        "imdb_url" => "https://www.imdb.com/title/tt0076759/"
      )
    end

    it "falls back to the search overview when details omit it" do
      stub_tmdb(
        search_body: { "results" => [ {
          "id" => 11,
          "poster_path" => "/abc.jpg",
          "overview" => "Search overview."
        } ] }.to_json,
        details_body: { "imdb_id" => "tt0076759", "overview" => "" }.to_json
      )

      expect(lookup.fetch("Star Wars")["description"]).to eq("Search overview.")
    end

    it "returns nil IMDb URL when details have no imdb_id" do
      stub_tmdb(
        search_body: { "results" => [ { "id" => 11, "poster_path" => "/abc.jpg", "overview" => "X" } ] }.to_json,
        details_body: { "imdb_id" => nil, "overview" => "X" }.to_json
      )

      expect(lookup.fetch("Star Wars")["imdb_url"]).to be_nil
    end

    it "returns nil when search results are empty" do
      stub_tmdb(search_body: { "results" => [] }.to_json)
      expect(lookup.fetch("Unknown")).to be_nil
    end

    it "returns nil when TMDB search fails" do
      stub_tmdb(search_body: "", search_success: false)
      expect(lookup.fetch("Anora")).to be_nil
    end

    it "returns nil and logs a warning when an exception is raised" do
      allow(Net::HTTP).to receive(:start).and_raise(SocketError, "connection failed")
      expect(Rails.logger).to receive(:warn).with(/TMDB lookup failed/)
      expect(lookup.fetch("Anora")).to be_nil
    end

    it "prefers a same-titled film from the ceremony year over a popular older hit" do
      stub_tmdb(
        search_body: { "results" => [
          {
            "id" => 941,
            "title" => "The Living Daylights",
            "release_date" => "1987-06-29",
            "poster_path" => "/bond.jpg",
            "overview" => "Bond."
          },
          {
            "id" => 758611,
            "title" => "Living",
            "release_date" => "2022-11-04",
            "poster_path" => "/living.jpg",
            "overview" => "A bureaucrat in 1950s London."
          }
        ] }.to_json,
        details_by_id: {
          941 => {
            "overview" => "Bond.",
            "imdb_id" => "tt0093428",
            "poster_path" => "/bond.jpg"
          },
          758611 => {
            "overview" => "A bureaucrat in 1950s London.",
            "imdb_id" => "tt9051908",
            "poster_path" => "/living.jpg"
          }
        }
      )

      result = lookup.fetch("Living", year: 2023)

      expect(result).to include(
        "poster_url" => "https://image.tmdb.org/t/p/w500/living.jpg",
        "imdb_url" => "https://www.imdb.com/title/tt9051908/"
      )
    end

    it "prefers the remake from the ceremony window when titles match" do
      stub_tmdb(
        search_body: { "results" => [
          {
            "id" => 871,
            "title" => "Dune",
            "release_date" => "1984-12-14",
            "poster_path" => "/dune84.jpg",
            "overview" => "Lynch."
          },
          {
            "id" => 438631,
            "title" => "Dune",
            "release_date" => "2021-09-15",
            "poster_path" => "/dune21.jpg",
            "overview" => "Villeneuve."
          }
        ] }.to_json,
        details_by_id: {
          871 => { "overview" => "Lynch.", "imdb_id" => "tt0087182", "poster_path" => "/dune84.jpg" },
          438631 => { "overview" => "Villeneuve.", "imdb_id" => "tt1160419", "poster_path" => "/dune21.jpg" }
        }
      )

      result = lookup.fetch("Dune", year: 2022)
      expect(result["imdb_url"]).to eq("https://www.imdb.com/title/tt1160419/")
    end
  end

  describe "#fetch_by_id" do
    it "returns poster, description, and IMDb URL from movie details" do
      stub_tmdb(
        search_body: { "results" => [] }.to_json,
        details_body: {
          "title" => "Star Wars",
          "overview" => "The full plot synopsis.",
          "imdb_id" => "tt0076759",
          "poster_path" => "/abc.jpg"
        }.to_json
      )

      expect(lookup.fetch_by_id(11)).to eq(
        "poster_url" => "https://image.tmdb.org/t/p/w500/abc.jpg",
        "description" => "The full plot synopsis.",
        "imdb_url" => "https://www.imdb.com/title/tt0076759/"
      )
    end

    it "returns nil when details request fails" do
      stub_tmdb(search_body: { "results" => [] }.to_json, details_body: "", details_success: false)
      expect(lookup.fetch_by_id(11)).to be_nil
    end
  end
end
