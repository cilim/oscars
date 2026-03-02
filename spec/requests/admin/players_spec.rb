require "rails_helper"

RSpec.describe "Admin::Players", type: :request do
  let(:admin)  { create(:user, :admin) }
  let(:season) { create(:season) }
  let(:user)   { create(:user) }

  before { sign_in(admin) }

  describe "POST /admin/seasons/:season_id/players" do
    it "adds a player to the season and redirects" do
      expect {
        post admin_season_players_path(season), params: { player: { user_id: user.id } }
      }.to change(Player, :count).by(1)
      expect(response).to redirect_to(admin_season_path(season))
    end

    it "redirects with alert on failure" do
      # duplicate player — second save should fail
      create(:player, season: season, user: user)
      post admin_season_players_path(season), params: { player: { user_id: user.id } }
      expect(response).to redirect_to(admin_season_path(season))
      expect(flash[:alert]).to be_present
    end
  end

  describe "DELETE /admin/seasons/:season_id/players/:id" do
    it "removes the player and redirects" do
      player = create(:player, season: season, user: user)
      expect {
        delete admin_season_player_path(season, player)
      }.to change(Player, :count).by(-1)
      expect(response).to redirect_to(admin_season_path(season))
    end
  end
end
