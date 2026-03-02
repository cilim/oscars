require "rails_helper"

RSpec.describe "Admin::SeasonCategories", type: :request do
  let(:admin)    { create(:user, :admin) }
  let(:season)   { create(:season) }
  let(:category) { create(:category) }

  before { sign_in(admin) }

  describe "POST /admin/seasons/:season_id/season_categories" do
    it "adds the category to the season and redirects" do
      expect {
        post admin_season_season_categories_path(season),
             params: { season_category: { category_id: category.id } }
      }.to change(SeasonCategory, :count).by(1)
      expect(response).to redirect_to(admin_season_path(season))
    end

    it "assigns an incrementing position" do
      create(:season_category, season: season, position: 3)
      post admin_season_season_categories_path(season),
           params: { season_category: { category_id: category.id } }
      expect(SeasonCategory.last.position).to eq(4)
    end

    it "redirects with alert on failure" do
      # Associate the same category twice — should fail uniqueness
      create(:season_category, season: season, category: category)
      post admin_season_season_categories_path(season),
           params: { season_category: { category_id: category.id } }
      expect(response).to redirect_to(admin_season_path(season))
      expect(flash[:alert]).to be_present
    end
  end

  describe "DELETE /admin/seasons/:season_id/season_categories/:id" do
    it "removes the season_category and redirects" do
      sc = create(:season_category, season: season, category: category)
      expect {
        delete admin_season_season_category_path(season, sc)
      }.to change(SeasonCategory, :count).by(-1)
      expect(response).to redirect_to(admin_season_path(season))
    end
  end
end
