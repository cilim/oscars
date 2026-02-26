require "rails_helper"

RSpec.describe Pick, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:player) }
    it { is_expected.to belong_to(:season_category) }
    it { is_expected.to belong_to(:think_will_win).class_name("Nominee").optional }
    it { is_expected.to belong_to(:want_to_win).class_name("Nominee").optional }
  end

  describe "validations" do
    subject { create(:pick) }
    it { is_expected.to validate_uniqueness_of(:season_category_id).scoped_to(:player_id) }
  end

  describe "scoring" do
    let(:season_category) { create(:season_category) }
    let(:nominee_a) { create(:nominee, season_category: season_category) }
    let(:nominee_b) { create(:nominee, season_category: season_category) }
    let(:player) { create(:player, season: season_category.season) }

    context "when no winner announced" do
      let(:pick) { create(:pick, player: player, season_category: season_category, think_will_win: nominee_a, want_to_win: nominee_b) }

      it "returns 0 for think_score" do
        expect(pick.think_score).to eq(0)
      end

      it "returns 0 for want_score" do
        expect(pick.want_score).to eq(0)
      end

      it "returns 0 for total_score" do
        expect(pick.total_score).to eq(0)
      end
    end

    context "when winner matches think_will_win" do
      let(:pick) { create(:pick, player: player, season_category: season_category, think_will_win: nominee_a, want_to_win: nominee_b) }

      before { create(:winner, season_category: season_category, nominee: nominee_a) }

      it "returns 5 for think_score" do
        expect(pick.think_score).to eq(5)
      end

      it "returns 0 for want_score" do
        expect(pick.want_score).to eq(0)
      end

      it "returns 5 for total_score" do
        expect(pick.total_score).to eq(5)
      end
    end

    context "when winner matches want_to_win" do
      let(:pick) { create(:pick, player: player, season_category: season_category, think_will_win: nominee_a, want_to_win: nominee_b) }

      before { create(:winner, season_category: season_category, nominee: nominee_b) }

      it "returns 0 for think_score" do
        expect(pick.think_score).to eq(0)
      end

      it "returns 2 for want_score" do
        expect(pick.want_score).to eq(2)
      end

      it "returns 2 for total_score" do
        expect(pick.total_score).to eq(2)
      end
    end

    context "when winner matches both" do
      let(:pick) { create(:pick, player: player, season_category: season_category, think_will_win: nominee_a, want_to_win: nominee_a) }

      before { create(:winner, season_category: season_category, nominee: nominee_a) }

      it "returns 7 for total_score" do
        expect(pick.total_score).to eq(7)
      end
    end
  end
end
