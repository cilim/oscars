require "rails_helper"

RSpec.describe "Scoreboards", type: :request do
  let(:user) { create(:user) }
  let(:season) { create(:season) }

  before { sign_in(user) }

  describe "GET /seasons/:season_id/scoreboard" do
    it "renders the scoreboard" do
      get season_scoreboard_path(season)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Live Scoreboard")
    end
  end
end
