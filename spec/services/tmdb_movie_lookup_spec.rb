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

  def stub_tmdb(search_body:, details_body: nil, search_success: true, details_success: true)
    search_response = mock_response(search_body, success: search_success)
    details_response = details_body ? mock_response(details_body, success: details_success) : nil

    allow(Net::HTTP).to receive(:start).with("api.themoviedb.org", 443, anything) do |*_args, **_opts, &blk|
      http = double("net_http")
      allow(http).to receive(:request) do |request|
        path = request.path
        if path.include?("/search/movie")
          search_response
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
