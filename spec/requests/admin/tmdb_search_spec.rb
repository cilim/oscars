require "rails_helper"

RSpec.describe "Admin::TmdbSearch", type: :request do
  let(:tmdb_json) do
    {
      "results" => [
        {
          "title"        => "Anora",
          "release_date" => "2024-10-18",
          "poster_path"  => "/abc123.jpg",
          "overview"     => "A young sex worker in New York marries the son of a Russian oligarch."
        },
        {
          "title"        => "Anora 2",
          "release_date" => "2025-01-01",
          "poster_path"  => nil,
          "overview"     => ""
        }
      ]
    }.to_json
  end

  def stub_tmdb(body: tmdb_json, success: true)
    response = double("tmdb_response")
    allow(response).to receive(:is_a?).and_return(false)
    allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(success)
    allow(response).to receive(:body).and_return(body)
    allow(response).to receive(:code).and_return(success ? "200" : "503")

    allow(Net::HTTP).to receive(:start) do |*_args, **_opts, &blk|
      http = double("net_http")
      allow(http).to receive(:request).and_return(response)
      blk.call(http)
    end
  end

  # ── As admin ─────────────────────────────────────────────────────────────────

  describe "as admin" do
    let(:admin) { create(:user, :admin) }

    before do
      sign_in(admin)
      allow(Rails.application.credentials).to receive(:tmdb_access_token).and_return("test_token")
    end

    describe "GET /admin/tmdb_search" do
      context "with a valid query" do
        before { stub_tmdb }

        it "returns 200" do
          get admin_tmdb_search_path, params: { query: "Anora" }
          expect(response).to have_http_status(:ok)
        end

        it "returns JSON content type" do
          get admin_tmdb_search_path, params: { query: "Anora" }
          expect(response.content_type).to include("application/json")
        end

        it "includes title, year, poster_url, and overview in each result" do
          get admin_tmdb_search_path, params: { query: "Anora" }
          result = JSON.parse(response.body).first
          expect(result).to include("title", "year", "poster_url", "overview")
        end

        it "maps release_date to the year string" do
          get admin_tmdb_search_path, params: { query: "Anora" }
          result = JSON.parse(response.body).first
          expect(result["year"]).to eq("2024")
        end

        it "builds the full poster URL" do
          get admin_tmdb_search_path, params: { query: "Anora" }
          result = JSON.parse(response.body).first
          expect(result["poster_url"]).to eq("https://image.tmdb.org/t/p/w500/abc123.jpg")
        end

        it "returns nil poster_url when poster_path is missing" do
          get admin_tmdb_search_path, params: { query: "Anora" }
          second = JSON.parse(response.body)[1]
          expect(second["poster_url"]).to be_nil
        end

        it "returns at most 5 results" do
          get admin_tmdb_search_path, params: { query: "Anora" }
          expect(JSON.parse(response.body).length).to be <= 5
        end

        it "truncates overview to 120 characters with ellipsis" do
          long_overview = "x" * 200
          stub_tmdb(body: { "results" => [ {
            "title" => "T", "release_date" => "2024-01-01",
            "poster_path" => nil, "overview" => long_overview
          } ] }.to_json)

          get admin_tmdb_search_path, params: { query: "T" }
          overview = JSON.parse(response.body).first["overview"]
          expect(overview).to end_with("…")
          expect(overview.length).to be <= 124
        end

        it "returns overview as-is when shorter than 120 characters" do
          get admin_tmdb_search_path, params: { query: "Anora" }
          overview = JSON.parse(response.body).first["overview"]
          expect(overview).not_to end_with("…")
        end
      end

      context "with a blank query" do
        it "returns 422" do
          get admin_tmdb_search_path, params: { query: "" }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "returns an error key in the JSON" do
          get admin_tmdb_search_path, params: { query: "" }
          expect(JSON.parse(response.body)).to have_key("error")
        end
      end

      context "without a query param at all" do
        it "returns 422" do
          get admin_tmdb_search_path
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "when TMDB credentials are not configured" do
        before { allow(Rails.application.credentials).to receive(:tmdb_access_token).and_return(nil) }

        it "returns 422" do
          get admin_tmdb_search_path, params: { query: "Anora" }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it "returns an error message" do
          get admin_tmdb_search_path, params: { query: "Anora" }
          expect(JSON.parse(response.body)["error"]).to match(/credentials/i)
        end
      end

      context "when TMDB returns a non-200 response" do
        before { stub_tmdb(success: false) }

        it "returns 502" do
          get admin_tmdb_search_path, params: { query: "Anora" }
          expect(response).to have_http_status(:bad_gateway)
        end
      end

      context "when the HTTP call raises an exception" do
        before do
          allow(Net::HTTP).to receive(:start).and_raise(StandardError, "SSL error")
        end

        it "returns 500" do
          get admin_tmdb_search_path, params: { query: "Anora" }
          expect(response).to have_http_status(:internal_server_error)
        end

        it "includes the error message" do
          get admin_tmdb_search_path, params: { query: "Anora" }
          expect(JSON.parse(response.body)["error"]).to include("SSL error")
        end
      end
    end
  end

  # ── As regular user ───────────────────────────────────────────────────────────

  describe "as a regular user" do
    let(:user) { create(:user) }
    before { sign_in(user) }

    it "redirects to root" do
      get admin_tmdb_search_path, params: { query: "Anora" }
      expect(response).to redirect_to(root_path)
    end
  end
end
