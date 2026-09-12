RSpec.describe "History", type: :request do
  let(:user) { create(:user) }

  describe "GET /history" do
    it "redirects unauthenticated visitors to sign in" do
      get history_path
      expect(response).to redirect_to(new_session_path)
    end

    context "when signed in" do
      before { sign_in(user) }

      it "renders an empty state when no winners exist" do
        get history_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("History")
        expect(response.body).to include("envelopes")
      end

      it "renders the three history charts when winners exist" do
        season = create(:season, year: 2022, name: "94th Academy Awards (2022)")
        picture = create(:season_category, season: season, category: create(:category, name: "Best Picture"))
        sound = create(:season_category, season: season, category: create(:category, name: "Best Sound"))
        effects = create(:season_category, season: season, category: create(:category, name: "Best Visual Effects"))
        coda = create(:nominee, season_category: picture, movie_name: "CODA")
        dune_sound = create(:nominee, season_category: sound, movie_name: "Dune")
        dune_effects = create(:nominee, season_category: effects, movie_name: "Dune")
        create(:winner, season_category: picture, nominee: coda)
        create(:winner, season_category: sound, nominee: dune_sound)
        create(:winner, season_category: effects, nominee: dune_effects)

        get history_path
        html = CGI.unescapeHTML(response.body)
        expect(response).to have_http_status(:ok)
        expect(html).to include("Who hogged the night?")
        expect(html).to include("Glory and heartbreak")
        expect(html).to include("Did Picture take the board?")
        expect(html).to include("data-controller=\"highchart\"")
        expect(html).to include("data-controller=\"heartbreak-chart\"")
        expect(html).to include("Ceremony decade")
        expect(html).to include("Dune")
        expect(html).to include("CODA")
      end

      it "links History in the pool nav" do
        get history_path
        nav = response.body[/<nav[\s\S]*?<\/nav>/]
        expect(nav).to include("History")
        expect(nav).to include(history_path)
      end
    end
  end
end
