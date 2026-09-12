RSpec.describe "Admin::Seasons", type: :request do
  describe "as admin" do
    let(:admin) { create(:user, :admin) }
    before { sign_in(admin) }

    describe "GET /admin/seasons" do
      it "lists seasons" do
        create(:season)
        get admin_seasons_path
        expect(response).to have_http_status(:ok)
      end

      it "shows an Admin/Pool switch with Admin selected and has no Back to Site link" do
        get admin_seasons_path
        nav = response.body[/<nav[\s\S]*?<\/nav>/]
        switch = nav[/world-switch[\s\S]*?<\/div>/]
        expect(switch).to include("Admin")
        expect(switch).to include("Pool")
        expect(nav).not_to include("Back to Site")
        expect(switch.index("Admin")).to be < switch.index("Pool")
        expect(nav.index("world-switch")).to be < nav.index(">Seasons<")
        expect(switch).to match(/world-switch__option--active[^>]*>Admin</)
        expect(switch).not_to match(/world-switch__option--active[^>]*>Pool</)
      end

      it "links to scrape, new season, and database backup without yaml import or edit" do
        season = create(:season, name: "97th Academy Awards")
        get admin_seasons_path

        expect(response.body).to include("Scrape Nominations")
        expect(response.body).to include("New Season")
        expect(response.body).to include("Database backup")
        expect(response.body).to include(admin_database_backup_path)
        expect(response.body).to include(admin_season_path(season))
        expect(response.body).not_to include("Import from data file")
        expect(response.body).not_to include("Edit")
        expect(response.body).not_to include("Manage")
      end
    end

    describe "GET /admin/seasons/:id" do
      it "returns 200" do
        season = create(:season)
        get admin_season_path(season)
        expect(response).to have_http_status(:ok)
      end

      it "renders categories, movies, and players as sibling columns" do
        season = create(:season)
        get admin_season_path(season)

        expect(response.body).to include("admin-season-layout")
        expect(response.body).to include("Movies")
        expect(response.body).to include("Players")
      end

      it "lets admins edit the season on the show page" do
        season = create(:season, name: "97th Academy Awards", year: 2025)
        get admin_season_path(season)

        expect(response.body).to include("97th Academy Awards")
        expect(response.body).to include("Lock picks")
        expect(response.body).to include("Archived")
        expect(response.body).to include("Delete season")
        expect(response.body).not_to include("Edit Season")
        expect(response.body).not_to include("Scoreboard")
      end

      it "does not N+1 movie queries when listing nominees" do
        season = create(:season)
        3.times do
          sc = create(:season_category, season: season)
          create_list(:nominee, 3, season_category: sc)
        end

        queries = capture_sql { get admin_season_path(season) }
        movie_queries = queries.select { |sql| sql.match?(/FROM ["']?movies["']?/i) }
        nominee_counts = queries.select { |sql| sql.match?(/COUNT.*nominees/i) }

        expect(response).to have_http_status(:ok)
        expect(movie_queries.size).to eq(1)
        expect(nominee_counts).to be_empty
      end
    end

    describe "GET /admin/seasons/new" do
      it "returns 200" do
        get new_admin_season_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/seasons" do
      let(:scoring_scheme) { ScoringScheme.find_by!(name: "Classic") }

      it "creates a season" do
        expect {
          post admin_seasons_path, params: {
            season: { name: "2026 Oscars", year: 2026, scoring_scheme_id: scoring_scheme.id }
          }
        }.to change(Season, :count).by(1)
        expect(response).to redirect_to(admin_season_path(Season.last))
      end

      it "re-renders new on invalid params" do
        post admin_seasons_path, params: { season: { name: "", year: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "GET /admin/seasons/:id/edit" do
      it "is not routed" do
        season = create(:season)
        get "/admin/seasons/#{season.id}/edit"
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "PATCH /admin/seasons/:id" do
      it "updates a season and returns to the show page" do
        season = create(:season)
        patch admin_season_path(season), params: { season: { name: "Updated Oscars" } }
        expect(season.reload.name).to eq("Updated Oscars")
        expect(response).to redirect_to(admin_season_path(season))
      end

      it "saves lock and archive toggles without a full page redirect" do
        season = create(:season, locked: false, archived: false)
        patch admin_season_path(season), params: { season: { locked: true } }, as: :turbo_stream
        expect(season.reload.locked?).to be true
        expect(response.media_type).to eq(Mime[:turbo_stream])
      end

      it "keeps scoring scheme options in the header after an inline save" do
        classic = ScoringScheme.find_by!(name: "Classic")
        chaos = create(:scoring_scheme, name: "Chaos")
        create(:pick_type, :think, scoring_scheme: chaos)
        season = create(:season, scoring_scheme: classic)

        patch admin_season_path(season),
              params: { season: { scoring_scheme_id: chaos.id } },
              as: :turbo_stream

        expect(season.reload.scoring_scheme).to eq(chaos)
        expect(response.body).to include(%(value="#{classic.id}"))
        expect(response.body).to include(%(value="#{chaos.id}"))
      end

      it "re-renders show on invalid params" do
        season = create(:season)
        patch admin_season_path(season), params: { season: { name: "", year: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("admin-season-layout")
      end
    end

    describe "DELETE /admin/seasons/:id" do
      it "deletes a season" do
        season = create(:season)
        expect { delete admin_season_path(season) }.to change(Season, :count).by(-1)
      end
    end
  end

  describe "as regular user" do
    let(:user) { create(:user) }
    before { sign_in(user) }

    it "redirects to root" do
      get admin_seasons_path
      expect(response).to redirect_to(root_path)
    end
  end
end
