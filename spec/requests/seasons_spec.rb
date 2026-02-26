require "rails_helper"

RSpec.describe "Seasons", type: :request do
  let(:user) { create(:user) }

  before { sign_in(user) }

  describe "GET /seasons" do
    it "lists active seasons" do
      season = create(:season)
      create(:season, :archived)

      get seasons_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(season.name)
    end
  end

  describe "GET /seasons/:id" do
    it "shows season details" do
      season = create(:season)
      get season_path(season)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(season.name)
    end
  end
end
