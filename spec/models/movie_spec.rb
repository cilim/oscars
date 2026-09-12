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

  describe ".normalized_name" do
    it "strips a trailing country in parentheses" do
      expect(described_class.normalized_name("Flow (Latvia)")).to eq("Flow")
      expect(described_class.normalized_name("The Secret Agent (Brazil)")).to eq("The Secret Agent")
    end

    it "keeps titles whose parentheses are not a country" do
      expect(described_class.normalized_name("Birdman or (The Unexpected Virtue of Ignorance)"))
        .to eq("Birdman or (The Unexpected Virtue of Ignorance)")
      expect(described_class.normalized_name("Flow (2024 film)")).to eq("Flow (2024 film)")
    end

    it "leaves a bare title unchanged" do
      expect(described_class.normalized_name("Flow")).to eq("Flow")
    end

    it "strips only a trailing country when the title already has parentheses" do
      expect(described_class.normalized_name(
        "Birdman or (The Unexpected Virtue of Ignorance) (Mexico)"
      )).to eq("Birdman or (The Unexpected Virtue of Ignorance)")
      expect(described_class.normalized_name("I'm Still Here (2024 film) (Brazil)"))
        .to eq("I'm Still Here (2024 film)")
    end
  end

  describe "name normalization" do
    it "stores a country-suffixed title without the country" do
      movie = create(:movie, name: "Flow (Latvia)")
      expect(movie.reload.name).to eq("Flow")
    end
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
