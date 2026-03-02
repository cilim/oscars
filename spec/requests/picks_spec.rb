require "rails_helper"

RSpec.describe "Picks", type: :request do
  let(:user) { create(:user) }
  let(:season) { create(:season) }
  let!(:player) { create(:player, user: user, season: season) }
  let(:season_category) { create(:season_category, season: season) }
  let!(:nominee1) { create(:nominee, season_category: season_category) }
  let!(:nominee2) { create(:nominee, season_category: season_category) }

  before { sign_in(user) }

  describe "GET /seasons/:season_id/picks/edit" do
    it "renders the picks form" do
      get edit_season_picks_path(season)
      expect(response).to have_http_status(:ok)
    end

    context "when season is locked" do
      let(:season) { create(:season, :locked) }

      it "redirects with alert" do
        get edit_season_picks_path(season)
        expect(response).to redirect_to(season_path(season))
      end
    end
  end

  describe "PATCH /seasons/:season_id/picks" do
    it "saves picks" do
      expect {
        patch season_picks_path(season), params: {
          picks: {
            season_category.id.to_s => {
              think_will_win_id: nominee1.id,
              want_to_win_id: nominee2.id
            }
          }
        }
      }.to change(Pick, :count).by(1)

      expect(response).to redirect_to(season_path(season))
      pick = Pick.last
      expect(pick.think_will_win).to eq(nominee1)
      expect(pick.want_to_win).to eq(nominee2)
    end

    it "accepts turbo_stream format and returns no content" do
      patch season_picks_path(season),
            params: { picks: { season_category.id.to_s => { think_will_win_id: nominee1.id, want_to_win_id: nominee2.id } } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:no_content)
    end

    it "re-renders edit on RecordInvalid" do
      allow_any_instance_of(Pick).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      patch season_picks_path(season), params: {
        picks: { season_category.id.to_s => { think_will_win_id: nominee1.id, want_to_win_id: nominee2.id } }
      }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "returns 422 on RecordInvalid with turbo_stream format" do
      allow_any_instance_of(Pick).to receive(:update!).and_raise(ActiveRecord::RecordInvalid)
      patch season_picks_path(season),
            params: { picks: { season_category.id.to_s => { think_will_win_id: nominee1.id, want_to_win_id: nominee2.id } } },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it "redirects with alert when the season is locked" do
      season.update!(locked: true)
      patch season_picks_path(season), params: { picks: {} }
      expect(response).to redirect_to(season_path(season))
    end
  end

  describe "when user is not a player in the season" do
    let(:other_season) { create(:season) }

    it "redirects with alert on edit" do
      get edit_season_picks_path(other_season)
      expect(response).to redirect_to(season_path(other_season))
    end
  end
end
