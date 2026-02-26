require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
    it { is_expected.to have_many(:players).dependent(:destroy) }
    it { is_expected.to have_many(:seasons).through(:players) }
  end

  describe "validations" do
    subject { create(:user) }
    it { is_expected.to validate_presence_of(:display_name) }
    it { is_expected.to validate_presence_of(:email_address) }
    it { is_expected.to validate_uniqueness_of(:email_address).case_insensitive }
  end

  describe "#admin?" do
    it "returns true for admins" do
      user = build(:user, :admin)
      expect(user.admin?).to be true
    end

    it "returns false for regular users" do
      user = build(:user)
      expect(user.admin?).to be false
    end
  end

  describe "email normalization" do
    it "downcases and strips email" do
      user = create(:user, email_address: "  FOO@BAR.com  ")
      expect(user.email_address).to eq("foo@bar.com")
    end
  end
end
