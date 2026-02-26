require "rails_helper"

RSpec.describe Winner, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:season_category) }
    it { is_expected.to belong_to(:nominee) }
  end

  describe "validations" do
    subject { create(:winner) }
    it { is_expected.to validate_uniqueness_of(:season_category_id) }
  end
end
