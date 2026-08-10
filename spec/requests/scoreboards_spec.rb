RSpec.describe "Scoreboards", type: :request do
  let(:user) { create(:user) }
  let(:season) { create(:season) }
  let(:locked_season) { create(:season, :locked) }

  before { sign_in(user) }

  describe "GET /seasons/:season_id/scoreboard" do
    context "when the season is locked" do
      it "renders the scoreboard" do
        get season_scoreboard_path(locked_season)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Live Scoreboard")
      end

      it "shows per-pick-type points on the winner row, not a total across players" do
        think_type = locked_season.scoring_scheme.pick_types.order(:display_order).first
        season_category = create(:season_category, season: locked_season)
        winner_nominee = create(:nominee, season_category: season_category, movie_name: "Winner Film")
        create(:winner, season_category: season_category, nominee: winner_nominee)

        player1 = create(:player, season: locked_season, user: create(:user, display_name: "alice"))
        player2 = create(:player, season: locked_season, user: create(:user, display_name: "bob"))
        create(:pick_selection, player: player1, season_category: season_category,
               pick_type: think_type, nominee: winner_nominee)
        create(:pick_selection, player: player2, season_category: season_category,
               pick_type: think_type, nominee: winner_nominee)

        get season_scoreboard_path(locked_season)

        expect(response.body).to include("+#{think_type.points_on_correct}")
        expect(response.body).not_to include("+#{think_type.points_on_correct * 2}")
        expect(response.body).to include("alice")
        expect(response.body).to include("bob")
      end

      it "shows points_on_incorrect for a correct non-winner pick (e.g. will lose)" do
        scheme = locked_season.scoring_scheme
        lose_type = create(:pick_type, scoring_scheme: scheme, name: "Will lose", emoji: "👎",
                           points_on_correct: 50, points_on_incorrect: 50, display_order: 99, color: "#eab308")
        season_category = create(:season_category, season: locked_season)
        winner_nominee = create(:nominee, season_category: season_category, movie_name: "Hamnet")
        loser_nominee = create(:nominee, season_category: season_category, movie_name: "Marty Supreme")
        create(:winner, season_category: season_category, nominee: winner_nominee)

        player = create(:player, season: locked_season, user: create(:user, display_name: "admin"))
        create(:pick_selection, player: player, season_category: season_category,
               pick_type: lose_type, nominee: loser_nominee)

        get season_scoreboard_path(locked_season)

        expect(response.body).to include("Marty Supreme")
        expect(response.body).to include("+#{lose_type.points_on_incorrect}")
        expect(response.body).to include("admin")
      end
    end

    context "when the season is not locked" do
      it "redirects to the season page with an alert" do
        get season_scoreboard_path(season)
        expect(response).to redirect_to(season_path(season))
        expect(flash[:alert]).to be_present
      end
    end
  end
end
