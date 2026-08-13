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

    context "when the user is a player" do
      let(:season) { create(:season) }
      let!(:player) { create(:player, user: user, season: season) }
      let(:think_type) { season.scoring_scheme.pick_types.order(:display_order).first }
      let!(:hate_type) do
        create(:pick_type, scoring_scheme: season.scoring_scheme,
               name: "Would hate to win", emoji: "😡",
               points_on_correct: -50, points_on_incorrect: 10,
               display_order: 3, color: "#c2410c")
      end
      let(:season_category) { create(:season_category, season: season, category: create(:category, name: "Best Picture")) }
      let!(:winner_nominee) { create(:nominee, season_category: season_category, movie_name: "Marty Supreme") }
      let!(:picked_loser) { create(:nominee, season_category: season_category, movie_name: "One Battle After Another") }
      let!(:unpicked_nominee) { create(:nominee, season_category: season_category, movie_name: "Hamnet") }

      it "lists every nominee, including ones the player did not pick" do
        create(:pick_selection, player: player, season_category: season_category,
               pick_type: think_type, nominee: picked_loser)

        get season_path(season)

        expect(response.body).to include("Marty Supreme")
        expect(response.body).to include("One Battle After Another")
        expect(response.body).to include("Hamnet")
      end

      it "lists nominees on pending categories before a winner is announced" do
        get season_path(season)

        expect(response.body).to include("Marty Supreme")
        expect(response.body).to include("Hamnet")

        page = Nokogiri::HTML(response.body)
        status = page.at_css("[data-category-id='#{season_category.id}'] [data-category-status]")
        expect(status.text).to match(/Pending/i)
      end

      it "colors a risky correct pick by signed points, not by matching the winner" do
        create(:winner, season_category: season_category, nominee: winner_nominee)
        create(:pick_selection, player: player, season_category: season_category,
               pick_type: hate_type, nominee: winner_nominee)

        get season_path(season)

        page = Nokogiri::HTML(response.body)
        chip = page.at_css("[data-nominee-id='#{winner_nominee.id}']")
        expect(chip).to be_present
        expect(chip.text).to include("-50")
        expect(chip["class"]).to include("text-red-600")
        expect(chip["class"]).not_to include("text-emerald")
      end

      it "shows points per pick type in the stats bar instead of correct counts" do
        create(:winner, season_category: season_category, nominee: winner_nominee)
        create(:pick_selection, player: player, season_category: season_category,
               pick_type: hate_type, nominee: winner_nominee)

        get season_path(season)

        expect(response.body).to include("-50")
        expect(response.body).not_to include("Correct")
      end

      it "does not show a risky label on the stats bar or nominee chips" do
        create(:pick_selection, player: player, season_category: season_category,
               pick_type: hate_type, nominee: winner_nominee)

        get season_path(season)

        page = Nokogiri::HTML(response.body)
        expect(page.text).not_to match(/\brisky\b/i)
      end

      it "opens the poster modal from a nominee chip that has a poster" do
        winner_nominee.update!(poster_url: "https://img.example.com/marty.jpg")

        get season_path(season)

        page = Nokogiri::HTML(response.body)
        chip = page.at_css("[data-nominee-id='#{winner_nominee.id}']")
        expect(chip.name).to eq("button")
        expect(chip["data-action"]).to eq("click->movie-poster#show")
        expect(chip["data-poster-url"]).to eq("https://img.example.com/marty.jpg")
        expect(chip["data-movie-title"]).to eq("Marty Supreme")
      end

      it "does not make a nominee chip clickable when there is no poster" do
        get season_path(season)

        page = Nokogiri::HTML(response.body)
        chip = page.at_css("[data-nominee-id='#{unpicked_nominee.id}']")
        expect(chip.name).to eq("span")
        expect(chip["data-action"]).to be_nil
      end
    end
  end
end
