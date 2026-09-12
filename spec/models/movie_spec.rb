RSpec.describe Movie, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:season) }
    it { is_expected.to have_many(:nominees).dependent(:restrict_with_error) }
  end

  describe "validations" do
    subject { create(:movie) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:season_id) }
  end

  describe "#modal_available?" do
    it "is false when poster, description, and IMDb URL are all blank" do
      movie = build(:movie, poster_url: nil, description: nil, imdb_url: nil)
      expect(movie.modal_available?).to be(false)
    end

    it "is true when a poster is present" do
      movie = build(:movie, poster_url: "https://img.example.com/a.jpg")
      expect(movie.modal_available?).to be(true)
    end

    it "is true when a description is present" do
      movie = build(:movie, description: "A gothic romance.")
      expect(movie.modal_available?).to be(true)
    end

    it "is true when an IMDb URL is present" do
      movie = build(:movie, imdb_url: "https://www.imdb.com/title/tt0076759/")
      expect(movie.modal_available?).to be(true)
    end
  end
end
