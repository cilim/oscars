RSpec.describe PickSelection, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:player) }
    it { is_expected.to belong_to(:season_category) }
    it { is_expected.to belong_to(:pick_type) }
    it { is_expected.to belong_to(:nominee) }
  end

  describe "validations" do
    subject { create(:pick_selection) }
    it { is_expected.to validate_uniqueness_of(:nominee_id).scoped_to(%i[player_id season_category_id pick_type_id]) }
  end

  describe "#score_for" do
    let(:season_category) { create(:season_category) }
    let(:nominee_a) { create(:nominee, season_category: season_category) }
    let(:nominee_b) { create(:nominee, season_category: season_category) }
    let(:player) { create(:player, season: season_category.season) }
    let(:think_type) { season_category.season.scoring_scheme.pick_types.order(:display_order).first }

    context "when no winner announced" do
      let(:selection) do
        create(:pick_selection, player: player, season_category: season_category,
               pick_type: think_type, nominee: nominee_a)
      end

      it "returns 0" do
        expect(selection.score_for(nil)).to eq(0)
      end
    end

    context "when selection matches winner" do
      let(:selection) do
        create(:pick_selection, player: player, season_category: season_category,
               pick_type: think_type, nominee: nominee_a)
      end

      before { create(:winner, season_category: season_category, nominee: nominee_a) }

      it "returns points on correct" do
        expect(selection.score_for(nominee_a.id)).to eq(think_type.points_on_correct)
      end
    end

    context "when selection does not match winner" do
      let(:selection) do
        create(:pick_selection, player: player, season_category: season_category,
               pick_type: think_type, nominee: nominee_a)
      end

      before { create(:winner, season_category: season_category, nominee: nominee_b) }

      it "returns points on incorrect" do
        expect(selection.score_for(nominee_b.id)).to eq(think_type.points_on_incorrect)
      end
    end
  end
end
