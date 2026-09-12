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
      expect(response.body).not_to include("world-switch")
    end

    context "as an admin" do
      let(:user) { create(:user, :admin) }

      it "shows an Admin/Pool switch with Pool selected before Seasons" do
        get seasons_path
        nav = response.body[/<nav[\s\S]*?<\/nav>/]
        switch = nav[/world-switch[\s\S]*?<\/div>/]
        expect(switch).to include("Admin")
        expect(switch).to include("Pool")
        expect(switch.index("Admin")).to be < switch.index("Pool")
        expect(nav.index("world-switch")).to be < nav.index(">Seasons<")
        expect(switch).to match(/world-switch__option--active[^>]*>Pool</)
        expect(switch).not_to match(/world-switch__option--active[^>]*>Admin</)
      end
    end
  end

  describe "GET /seasons/:id" do
    it "shows season details" do
      season = create(:season)
      get season_path(season)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(season.name)
      expect(response.body).to include("/imdb-badge.svg")
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
        winner_nominee.movie.update!(poster_url: "https://img.example.com/marty.jpg")

        get season_path(season)

        page = Nokogiri::HTML(response.body)
        chip = page.at_css("[data-nominee-id='#{winner_nominee.id}']")
        expect(chip.name).to eq("button")
        expect(chip["data-action"]).to eq("click->movie-poster#show")
        expect(chip["data-poster-url"]).to eq("https://img.example.com/marty.jpg")
        expect(chip["data-movie-title"]).to eq("Marty Supreme")
      end

      it "opens the modal when a description is present without a poster" do
        unpicked_nominee.movie.update!(description: "A story of grief and creation.")

        get season_path(season)

        page = Nokogiri::HTML(response.body)
        chip = page.at_css("[data-nominee-id='#{unpicked_nominee.id}']")
        expect(chip.name).to eq("button")
        expect(chip["data-movie-description"]).to eq("A story of grief and creation.")
      end

      it "includes the IMDb URL on a clickable chip" do
        winner_nominee.movie.update!(
          poster_url: "https://img.example.com/marty.jpg",
          imdb_url: "https://www.imdb.com/title/tt0000001/"
        )

        get season_path(season)

        page = Nokogiri::HTML(response.body)
        chip = page.at_css("[data-nominee-id='#{winner_nominee.id}']")
        expect(chip["data-imdb-url"]).to eq("https://www.imdb.com/title/tt0000001/")
      end

      it "places the IMDb badge next to the modal title instead of a text link" do
        get season_path(season)

        page = Nokogiri::HTML(response.body)
        dialog = page.at_css("dialog.poster-dialog")
        title_row = dialog.at_css("[data-movie-poster-target='title']").parent
        badge = title_row.at_css("img.imdb-badge")

        expect(badge["src"]).to eq("/imdb-badge.svg")
        expect(dialog.text).not_to include("View on IMDb")
      end

      it "does not make a nominee chip clickable when there is no poster, description, or IMDb URL" do
        get season_path(season)

        page = Nokogiri::HTML(response.body)
        chip = page.at_css("[data-nominee-id='#{unpicked_nominee.id}']")
        expect(chip.name).to eq("span")
        expect(chip["data-action"]).to be_nil
      end

      it "does not N+1 movie queries when rendering nominee chips" do
        extra = create(:season_category, season: season, category: create(:category, name: "Best Director"))
        create_list(:nominee, 4, season_category: extra)

        queries = capture_sql { get season_path(season) }
        movie_queries = queries.select { |sql| sql.match?(/FROM ["']?movies["']?/i) }

        expect(response).to have_http_status(:ok)
        expect(movie_queries.size).to eq(1)
      end
    end
  end
end
