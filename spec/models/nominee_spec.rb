require "rails_helper"

RSpec.describe Nominee, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:season_category) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:movie_name) }
  end

  describe "#display_name" do
    it "returns movie name when no person" do
      nominee = build(:nominee, movie_name: "Anora", person_name: nil)
      expect(nominee.display_name).to eq("Anora")
    end

    it "returns person and movie when person present" do
      nominee = build(:nominee, movie_name: "The Brutalist", person_name: "Brady Corbet")
      expect(nominee.display_name).to eq("Brady Corbet — The Brutalist")
    end
  end
end
