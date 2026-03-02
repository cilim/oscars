require "rails_helper"

RSpec.describe "Admin::Winners", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:season) { create(:season) }
  let(:season_category) { create(:season_category, season: season) }
  let!(:nominee) { create(:nominee, season_category: season_category) }

  before { sign_in(admin) }

  describe "POST /admin/seasons/:season_id/winners" do
    it "creates a winner and redirects" do
      expect {
        post admin_season_winners_path(season), params: {
          winner: { season_category_id: season_category.id, nominee_id: nominee.id }
        }
      }.to change(Winner, :count).by(1)
      expect(response).to redirect_to(season_scoreboard_path(season))
    end

    it "accepts turbo_stream format" do
      post admin_season_winners_path(season),
           params: { winner: { season_category_id: season_category.id, nominee_id: nominee.id } },
           headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:ok)
    end

    it "redirects with alert when save fails" do
      allow_any_instance_of(Winner).to receive(:save).and_return(false)
      post admin_season_winners_path(season), params: {
        winner: { season_category_id: season_category.id, nominee_id: nominee.id }
      }
      expect(response).to redirect_to(season_scoreboard_path(season))
      expect(flash[:alert]).to be_present
    end
  end

  describe "DELETE /admin/seasons/:season_id/winners/:id" do
    it "removes a winner" do
      winner = create(:winner, season_category: season_category, nominee: nominee)
      expect {
        delete admin_season_winner_path(season, winner)
      }.to change(Winner, :count).by(-1)
    end
  end
end
