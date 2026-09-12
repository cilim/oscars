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
      expect(Movie.find_by(season: season, name: "Anora")).to be_present
      expect(response).to redirect_to(admin_season_path(season))
    end

    it "reuses an existing movie in the season without wiping its metadata" do
      existing = create(:movie, season: season, name: "Anora",
                                poster_url: "https://img.example.com/a.jpg",
                                description: "Keep me",
                                imdb_url: "https://www.imdb.com/title/tt28607951/")
      expect {
        post admin_season_season_category_nominees_path(season, season_category),
             params: { nominee: { movie_name: "Anora", person_name: "Mikey Madison" } }
      }.to change(Nominee, :count).by(1)
       .and change(Movie, :count).by(0)
      expect(Nominee.last.movie).to eq(existing)
      existing.reload
      expect(existing.poster_url).to eq("https://img.example.com/a.jpg")
      expect(existing.description).to eq("Keep me")
      expect(existing.imdb_url).to eq("https://www.imdb.com/title/tt28607951/")
    end

    it "saves description and IMDb URL on the movie" do
      post admin_season_season_category_nominees_path(season, season_category),
           params: { nominee: {
             movie_name: "Anora",
             description: "A Cinderella story.",
             imdb_url: "https://www.imdb.com/title/tt28607951/"
           } }
      movie = Movie.find_by!(name: "Anora")
      expect(movie.description).to eq("A Cinderella story.")
      expect(movie.imdb_url).to eq("https://www.imdb.com/title/tt28607951/")
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

    it "updates shared movie metadata when editing a nominee of that movie" do
      patch admin_season_season_category_nominee_path(season, season_category, nominee),
            params: { nominee: {
              movie_name: nominee.movie_name,
              description: "A Cinderella story.",
              imdb_url: "https://www.imdb.com/title/tt28607951/"
            } }
      movie = nominee.reload.movie
      expect(movie.description).to eq("A Cinderella story.")
      expect(movie.imdb_url).to eq("https://www.imdb.com/title/tt28607951/")
    end

    it "allows clearing movie metadata when editing" do
      nominee.movie.update!(description: "Keep me", imdb_url: "https://www.imdb.com/title/tt28607951/")
      patch admin_season_season_category_nominee_path(season, season_category, nominee),
            params: { nominee: { movie_name: nominee.movie_name, description: "", imdb_url: "" } }
      movie = nominee.reload.movie
      expect(movie.description).to be_nil
      expect(movie.imdb_url).to be_nil
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
