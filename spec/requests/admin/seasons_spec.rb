require "rails_helper"

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
    end

    describe "GET /admin/seasons/:id" do
      it "returns 200" do
        season = create(:season)
        get admin_season_path(season)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /admin/seasons/new" do
      it "returns 200" do
        get new_admin_season_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/seasons" do
      it "creates a season" do
        expect {
          post admin_seasons_path, params: { season: { name: "2026 Oscars", year: 2026 } }
        }.to change(Season, :count).by(1)
        expect(response).to redirect_to(admin_season_path(Season.last))
      end

      it "re-renders new on invalid params" do
        post admin_seasons_path, params: { season: { name: "", year: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "GET /admin/seasons/:id/edit" do
      it "returns 200" do
        season = create(:season)
        get edit_admin_season_path(season)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "PATCH /admin/seasons/:id" do
      it "updates a season" do
        season = create(:season)
        patch admin_season_path(season), params: { season: { locked: true } }
        expect(season.reload.locked?).to be true
      end

      it "re-renders edit on invalid params" do
        season = create(:season)
        patch admin_season_path(season), params: { season: { name: "", year: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
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
