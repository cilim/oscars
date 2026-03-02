require "rails_helper"

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
