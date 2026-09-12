RSpec.describe "Picks", type: :request do
  let(:user) { create(:user) }
  let(:season) { create(:season) }
  let!(:player) { create(:player, user: user, season: season) }
  let(:season_category) { create(:season_category, season: season) }
  let!(:nominee1) { create(:nominee, season_category: season_category) }
  let!(:nominee2) { create(:nominee, season_category: season_category) }
  let(:think_type) { season.scoring_scheme.pick_types.order(:display_order).first }
  let(:want_type) { season.scoring_scheme.pick_types.order(:display_order).second }

  let(:pick_params) do
    {
      season_category.id.to_s => {
        think_type.id.to_s => { nominee_ids: [ nominee1.id ] },
        want_type.id.to_s => { nominee_ids: [ nominee2.id ] }
      }
    }
  end

  before { sign_in(user) }

  describe "GET /seasons/:season_id/picks/edit" do
    it "renders the picks form" do
      get edit_season_picks_path(season)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(season.name)
      expect(response.body).to include("Make Your Picks")
      expect(response.body).not_to include("Picks save automatically")
    end

    it "does not N+1 movie queries when rendering nominees" do
      extra = create(:season_category, season: season, category: create(:category, name: "Best Director"))
      create_list(:nominee, 4, season_category: extra)

      queries = capture_sql { get edit_season_picks_path(season) }
      movie_queries = queries.select { |sql| sql.match?(/FROM ["']?movies["']?/i) }

      expect(response).to have_http_status(:ok)
      expect(movie_queries.size).to eq(1)
    end

    it "makes a poster and title open the movie modal when metadata is present" do
      nominee1.movie.update!(poster_url: "https://img.example.com/a.jpg", description: "A plot.")

      get edit_season_picks_path(season)

      page = Nokogiri::HTML(response.body)
      poster = page.at_css("[data-poster-wrap][data-nominee-id]") || page.at_css(%([data-action="click->movie-poster#show"]))
      expect(poster).to be_present
      expect(page.css(%([data-action="click->movie-poster#show"])).length).to be >= 2
      expect(page.at_css(%([data-poster-url="https://img.example.com/a.jpg"]))).to be_present
      expect(page.at_css(%([data-movie-description="A plot."]))).to be_present
    end

    it "renders a pick pool for each pick type" do
      get edit_season_picks_path(season)

      expect(response.body).to include("pick-pool")
      expect(response.body).to include("data-pool-remaining=\"#{think_type.id}\"")
      expect(response.body).to include("data-pool-remaining=\"#{want_type.id}\"")
      expect(response.body).not_to include("data-pick-counter")
    end

    context "with a multi-select pick type" do
      let(:scheme) { create(:scoring_scheme, name: "Pool Scheme") }
      let!(:think_type) { create(:pick_type, :think, scoring_scheme: scheme) }
      let!(:want_type) { create(:pick_type, :want, :multi, scoring_scheme: scheme, max_selections: 20) }
      let(:season) { create(:season, scoring_scheme: scheme) }

      it "renders a pool token for each available pick" do
        get edit_season_picks_path(season)

        page = Nokogiri::HTML(response.body)
        tokens = page.css(%([data-picks-carousel-target="poolToken"][data-pick-type-id="#{want_type.id}"]))
        expect(tokens.size).to eq(20)
      end
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
        patch season_picks_path(season), params: { picks: pick_params }
      }.to change(PickSelection, :count).by(2)

      expect(response).to redirect_to(season_path(season))
      selections = player.pick_selections.where(season_category: season_category)
      expect(selections.map(&:nominee_id)).to contain_exactly(nominee1.id, nominee2.id)
    end

    it "accepts turbo_stream format and returns no content" do
      patch season_picks_path(season),
            params: { picks: pick_params },
            headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:no_content)
    end

    it "re-renders edit on validation error" do
      allow_any_instance_of(Player).to receive(:pick_selections).and_raise(ActiveRecord::RecordInvalid.new(PickSelection.new))

      patch season_picks_path(season), params: { picks: pick_params }
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
