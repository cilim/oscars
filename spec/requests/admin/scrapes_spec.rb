require "rails_helper"

RSpec.describe "Admin::Scrapes", type: :request do
  let(:scraper_data) do
    {
      "season"     => { "name" => "98th Academy Awards (2026)", "year" => 2026 },
      "categories" => [
        {
          "name"       => "Best Picture",
          "has_person" => false,
          "nominees"   => [ { "movie" => "Anora", "person" => nil, "poster_url" => nil } ]
        }
      ]
    }
  end

  let(:import_params) do
    {
      season: { name: "98th Academy Awards (2026)", year: 2026 },
      categories: {
        "0" => {
          name:      "Best Picture",
          has_person: "0",
          nominees:  { "0" => { movie: "Anora", person: "", poster_url: "" } }
        }
      }
    }
  end

  # ── As admin ─────────────────────────────────────────────────────────────────

  describe "as admin" do
    let(:admin) { create(:user, :admin) }
    before { sign_in(admin) }

    # GET /admin/scrapes/new
    describe "GET /admin/scrapes/new" do
      it "returns 200" do
        get new_admin_scrape_path
        expect(response).to have_http_status(:ok)
      end
    end

    # POST /admin/scrapes (create)
    describe "POST /admin/scrapes" do
      context "with a valid year and successful scrape" do
        before do
          scraper = instance_double(OscarsScraper, call: scraper_data, errors: [])
          allow(OscarsScraper).to receive(:new).with(2026).and_return(scraper)
        end

        it "returns 200 and renders the preview" do
          post admin_scrapes_path, params: { year: 2026 }
          expect(response).to have_http_status(:ok)
        end
      end

      context "when the scraper returns an error" do
        before do
          scraper = instance_double(OscarsScraper, call: nil, errors: ["Wikipedia page not found"])
          allow(OscarsScraper).to receive(:new).with(2026).and_return(scraper)
        end

        it "re-renders the new form with unprocessable_entity" do
          post admin_scrapes_path, params: { year: 2026 }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "with a year below the allowed minimum" do
        it "re-renders the new form with unprocessable_entity" do
          post admin_scrapes_path, params: { year: 1900 }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "with a year above the allowed maximum" do
        it "re-renders the new form with unprocessable_entity" do
          post admin_scrapes_path, params: { year: Time.current.year + 10 }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    # POST /admin/scrapes/import
    describe "POST /admin/scrapes/import" do
      context "when the import succeeds" do
        it "creates a Season" do
          expect { post import_admin_scrapes_path, params: import_params }.to change(Season, :count).by(1)
        end

        it "redirects to the admin season page" do
          post import_admin_scrapes_path, params: import_params
          expect(response).to redirect_to(admin_season_path(Season.last))
        end
      end

      context "when the importer fails" do
        before do
          importer = instance_double(SeasonImporter, call: nil, errors: ["Validation failed"])
          allow(SeasonImporter).to receive(:new).and_return(importer)
        end

        it "re-renders the preview with unprocessable_entity" do
          post import_admin_scrapes_path, params: import_params
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context "with all nominees having blank movie names" do
        let(:blank_params) do
          {
            season: { name: "Test", year: 2099 },
            categories: {
              "0" => {
                name:      "Best Picture",
                has_person: "0",
                nominees:  { "0" => { movie: "", person: "", poster_url: "" } }
              }
            }
          }
        end

        it "creates the season but no nominees" do
          expect { post import_admin_scrapes_path, params: blank_params }.to change(Season, :count).by(1)
          expect(Nominee.count).to eq(0)
        end
      end
    end
  end

  # ── As regular user ───────────────────────────────────────────────────────────

  describe "as a regular user" do
    let(:user) { create(:user) }
    before { sign_in(user) }

    it "redirects GET /admin/scrapes/new to root" do
      get new_admin_scrape_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects POST /admin/scrapes to root" do
      post admin_scrapes_path, params: { year: 2026 }
      expect(response).to redirect_to(root_path)
    end

    it "redirects POST /admin/scrapes/import to root" do
      post import_admin_scrapes_path, params: import_params
      expect(response).to redirect_to(root_path)
    end
  end
end
