RSpec.describe "Admin::ScoringSchemes", type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in(admin) }

  describe "GET /admin/scoring_schemes" do
    it "lists scoring schemes" do
      create(:scoring_scheme, name: "Chaos Mode")
      get admin_scoring_schemes_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Chaos Mode")
    end
  end

  describe "POST /admin/scoring_schemes" do
    it "creates a scheme and redirects to edit" do
      post admin_scoring_schemes_path, params: { scoring_scheme: { name: "New Scheme" } }
      expect(response).to redirect_to(edit_admin_scoring_scheme_path(ScoringScheme.last))
      expect(ScoringScheme.last.name).to eq("New Scheme")
    end
  end

  describe "PATCH /admin/scoring_schemes/:id" do
    it "updates pick types when scheme is not locked" do
      scheme = create(:scoring_scheme)
      pick_type = create(:pick_type, scoring_scheme: scheme, name: "Old name")

      patch admin_scoring_scheme_path(scheme), params: {
        scoring_scheme: {
          name: scheme.name,
          pick_types_attributes: {
            "0" => {
              id: pick_type.id,
              name: "Updated name",
              emoji: pick_type.emoji,
              points_on_correct: 10,
              points_on_incorrect: -1,
              display_order: 1,
              color: pick_type.color,
              allow_multiple_selections: false
            }
          }
        }
      }

      expect(response).to redirect_to(edit_admin_scoring_scheme_path(scheme))
      expect(pick_type.reload.name).to eq("Updated name")
      expect(pick_type.points_on_correct).to eq(10)
    end

    it "blocks edits when picks reference the scheme" do
      scheme = create(:scoring_scheme, name: "Locked Scheme")
      pick_type = create(:pick_type, scoring_scheme: scheme)
      season = create(:season, scoring_scheme: scheme)
      player = create(:player, season: season)
      season_category = create(:season_category, season: season)
      create(:pick_selection, player: player, season_category: season_category,
             pick_type: pick_type, nominee: create(:nominee, season_category: season_category))

      patch admin_scoring_scheme_path(scheme), params: { scoring_scheme: { name: "Renamed" } }

      expect(response).to redirect_to(edit_admin_scoring_scheme_path(scheme))
      expect(flash[:alert]).to include("cannot be edited")
      expect(scheme.reload.name).to eq("Locked Scheme")
    end
  end

  describe "DELETE /admin/scoring_schemes/:id" do
    it "deletes an unused scheme" do
      scheme = create(:scoring_scheme, name: "Disposable")
      create(:pick_type, scoring_scheme: scheme)

      expect {
        delete admin_scoring_scheme_path(scheme)
      }.to change(ScoringScheme, :count).by(-1)
    end

    it "does not delete a scheme assigned to a season" do
      scheme = create(:scoring_scheme, name: "Assigned Scheme")
      create(:pick_type, scoring_scheme: scheme)
      create(:season, scoring_scheme: scheme, name: "Assigned Season", year: 2099)

      delete admin_scoring_scheme_path(scheme)

      expect(response).to redirect_to(admin_scoring_schemes_path)
      expect(ScoringScheme.exists?(scheme.id)).to be(true)
    end
  end
end
