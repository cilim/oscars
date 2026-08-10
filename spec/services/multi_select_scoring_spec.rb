RSpec.describe "Multi-select scoring" do
  let(:scheme) { create(:scoring_scheme, name: "Chaos") }
  let!(:pick_type) do
    create(:pick_type, :multi, scoring_scheme: scheme, name: "Shouldn't have been made", emoji: "😡",
           display_order: 1, color: "#ef4444")
  end
  let(:season) { create(:season, scoring_scheme: scheme) }
  let(:season_category) { create(:season_category, season: season) }
  let(:player) { create(:player, season: season) }
  let(:nominees) { create_list(:nominee, 3, season_category: season_category) }

  before do
    nominees.each do |nominee|
      create(:pick_selection, player: player, season_category: season_category, pick_type: pick_type, nominee: nominee)
    end
  end

  it "sums incorrect outcomes without a cap" do
    winner = create(:nominee, season_category: season_category)
    create(:winner, season_category: season_category, nominee: winner)

    entry = ScoreboardCalculator.new(season).call.find { |row| row[:player_id] == player.id }
    type_score = entry[:pick_type_scores].find { |row| row[:pick_type_id] == pick_type.id }[:score]

    expect(type_score).to eq(15)
    expect(entry[:total_score]).to eq(15)
  end
end
