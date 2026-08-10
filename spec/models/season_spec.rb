RSpec.describe Season, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:season_categories).dependent(:destroy) }
    it { is_expected.to have_many(:categories).through(:season_categories) }
    it { is_expected.to have_many(:players).dependent(:destroy) }
    it { is_expected.to have_many(:users).through(:players) }
  end

  describe "validations" do
    subject { create(:season) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
    it { is_expected.to validate_presence_of(:year) }

    it "allows multiple seasons in the same year" do
      create(:season, name: "Classic League 2026", year: 2026)
      duplicate_year = build(:season, name: "Chaos League 2026", year: 2026)

      expect(duplicate_year).to be_valid
    end
  end

  describe ".active" do
    it "returns non-archived seasons ordered by year desc" do
      old = create(:season, year: 2023, name: "2023 Oscars")
      new_season = create(:season, year: 2025, name: "2025 Oscars")
      create(:season, year: 2024, name: "2024 Oscars", archived: true)

      expect(Season.active).to eq([ new_season, old ])
    end
  end
end
