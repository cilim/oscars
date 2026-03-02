require "rails_helper"

RSpec.describe "Admin::Nominees", type: :request do
  let(:admin)           { create(:user, :admin) }
  let(:season)          { create(:season) }
  let(:season_category) { create(:season_category, season: season) }

  before { sign_in(admin) }

  describe "GET /admin/seasons/:season_id/season_categories/:sc_id/nominees/new" do
    it "returns 200" do
      get new_admin_season_season_category_nominee_path(season, season_category)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /admin/seasons/:season_id/season_categories/:sc_id/nominees" do
    it "creates a nominee and redirects" do
      expect {
        post admin_season_season_category_nominees_path(season, season_category),
             params: { nominee: { movie_name: "Anora", person_name: nil, poster_url: nil } }
      }.to change(Nominee, :count).by(1)
      expect(response).to redirect_to(admin_season_path(season))
    end

    it "re-renders new on invalid params" do
      post admin_season_season_category_nominees_path(season, season_category),
           params: { nominee: { movie_name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /admin/seasons/:season_id/season_categories/:sc_id/nominees/:id/edit" do
    it "returns 200" do
      nominee = create(:nominee, season_category: season_category)
      get edit_admin_season_season_category_nominee_path(season, season_category, nominee)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /admin/seasons/:season_id/season_categories/:sc_id/nominees/:id" do
    let(:nominee) { create(:nominee, season_category: season_category) }

    it "updates and redirects" do
      patch admin_season_season_category_nominee_path(season, season_category, nominee),
            params: { nominee: { movie_name: "New Title" } }
      expect(nominee.reload.movie_name).to eq("New Title")
      expect(response).to redirect_to(admin_season_path(season))
    end

    it "re-renders edit on invalid params" do
      patch admin_season_season_category_nominee_path(season, season_category, nominee),
            params: { nominee: { movie_name: "" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "DELETE /admin/seasons/:season_id/season_categories/:sc_id/nominees/:id" do
    it "destroys the nominee and redirects" do
      nominee = create(:nominee, season_category: season_category)
      expect {
        delete admin_season_season_category_nominee_path(season, season_category, nominee)
      }.to change(Nominee, :count).by(-1)
      expect(response).to redirect_to(admin_season_path(season))
    end
  end
end
