require "rails_helper"

RSpec.describe Category, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:season_categories).dependent(:destroy) }
    it { is_expected.to have_many(:seasons).through(:season_categories) }
  end

  describe "validations" do
    subject { create(:category) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end
end
