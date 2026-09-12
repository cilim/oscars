RSpec.describe "Admin::Movies", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:season) { create(:season) }
  let(:season_category) { create(:season_category, season: season) }
  let!(:movie) do
    create(:movie, season: season, name: "Anora",
                   poster_url: "https://img.example.com/anora.jpg")
  end
  let!(:nominee) { create(:nominee, season_category: season_category, movie: movie) }

  describe "as admin" do
    before { sign_in(admin) }

    describe "GET /admin/seasons/:season_id" do
      it "lists the season's movies with an edit link" do
        get admin_season_path(season)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Movies")
        expect(response.body).to include("Anora")
        expect(response.body).to include(edit_admin_season_movie_path(season, movie))
      end
    end

    describe "GET /admin/seasons/:season_id/movies/:id/edit" do
      it "returns 200 with the movie form" do
        get edit_admin_season_movie_path(season, movie)

        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Anora")
        expect(response.body).to include("Description")
        expect(response.body).to include("IMDb URL")
      end

      it "prefills TMDB search and shows lookup data" do
        allow(Rails.application.credentials).to receive(:tmdb_access_token).and_return("tok")
        lookup = instance_double(TmdbMovieLookup)
        allow(TmdbMovieLookup).to receive(:new).and_return(lookup)
        allow(lookup).to receive(:fetch).with("Anora").and_return(
          "poster_url" => "https://image.tmdb.org/t/p/w500/abc.jpg",
          "description" => "A sex worker's Cinderella story.",
          "imdb_url" => "https://www.imdb.com/title/tt28607951/"
        )

        get edit_admin_season_movie_path(season, movie)

        page = Nokogiri::HTML(response.body)
        expect(page.at_css("[data-tmdb-search-target='input']")["value"]).to eq("Anora")
        expect(page.text).to include("A sex worker's Cinderella story.")
        expect(page.text).to include("https://www.imdb.com/title/tt28607951/")
      end

      it "does not find a movie from another season" do
        other = create(:movie, name: "Anora")
        get edit_admin_season_movie_path(season, other)
        expect(response).to have_http_status(:not_found)
      end
    end

    describe "PATCH /admin/seasons/:season_id/movies/:id" do
      it "updates description and IMDb URL and redirects" do
        patch admin_season_movie_path(season, movie), params: {
          movie: {
            name: "Anora",
            poster_url: movie.poster_url,
            description: "A Cinderella story.",
            imdb_url: "https://www.imdb.com/title/tt28607951/"
          }
        }

        expect(response).to redirect_to(admin_season_path(season))
        movie.reload
        expect(movie.description).to eq("A Cinderella story.")
        expect(movie.imdb_url).to eq("https://www.imdb.com/title/tt28607951/")
      end

      it "re-renders edit on invalid params" do
        patch admin_season_movie_path(season, movie), params: { movie: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "merges into an existing movie when the name only adds a country suffix" do
        duplicate = create(:movie, season: season, name: "Anora Placeholder")
        duplicate.update_column(:name, "Anora (United States)")
        other_category = create(:season_category, season: season)
        dup_nominee = create(:nominee, season_category: other_category, movie: duplicate)

        patch admin_season_movie_path(season, duplicate), params: {
          movie: { name: "Anora (United States)", poster_url: "", description: "", imdb_url: "" }
        }

        expect(response).to redirect_to(admin_season_path(season))
        expect(Movie.find_by(id: duplicate.id)).to be_nil
        expect(dup_nominee.reload.movie).to eq(movie)
        expect(Movie.where(season: season, name: "Anora").count).to eq(1)
      end

      it "does not merge when renaming to another movie's exact title" do
        other = create(:movie, season: season, name: "Wicked")
        create(:nominee, season_category: create(:season_category, season: season), movie: other)

        patch admin_season_movie_path(season, movie), params: {
          movie: { name: "Wicked", poster_url: movie.poster_url, description: "", imdb_url: "" }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(Movie.find_by(id: movie.id)).to eq(movie)
        expect(Movie.find_by(id: other.id)).to eq(other)
        expect(movie.reload.name).to eq("Anora")
      end
    end
  end

  describe "as a regular user" do
    let(:user) { create(:user) }
    before { sign_in(user) }

    it "redirects away from the movie edit page" do
      get edit_admin_season_movie_path(season, movie)
      expect(response).to redirect_to(root_path)
    end
  end
end
