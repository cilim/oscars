RSpec.describe Nominee, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:season_category) }
    it { is_expected.to belong_to(:movie) }
  end

  describe "#display_name" do
    it "returns movie name when no person" do
      movie = build(:movie, name: "Anora")
      nominee = build(:nominee, movie: movie, person_name: nil)
      expect(nominee.display_name).to eq("Anora")
    end

    it "returns person and movie when person present" do
      movie = build(:movie, name: "The Brutalist")
      nominee = build(:nominee, movie: movie, person_name: "Brady Corbet")
      expect(nominee.display_name).to eq("Brady Corbet — The Brutalist")
    end
  end

  describe "movie field delegates" do
    it "exposes the movie name as movie_name" do
      movie = build(:movie, name: "Hamnet")
      nominee = build(:nominee, movie: movie)
      expect(nominee.movie_name).to eq("Hamnet")
    end

    it "exposes poster_url, description, and imdb_url from the movie" do
      movie = build(:movie,
                    poster_url: "https://img.example.com/h.jpg",
                    description: "A story of grief.",
                    imdb_url: "https://www.imdb.com/title/tt123/")
      nominee = build(:nominee, movie: movie)
      expect(nominee.poster_url).to eq("https://img.example.com/h.jpg")
      expect(nominee.description).to eq("A story of grief.")
      expect(nominee.imdb_url).to eq("https://www.imdb.com/title/tt123/")
    end
  end
end
