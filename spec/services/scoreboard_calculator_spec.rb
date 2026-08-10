RSpec.describe ScoreboardCalculator do
  let(:season) { create(:season) }
  let(:think_type) { season.scoring_scheme.pick_types.order(:display_order).first }
  let(:want_type) { season.scoring_scheme.pick_types.order(:display_order).second }
  let(:sc1) { create(:season_category, season: season) }
  let(:sc2) { create(:season_category, season: season) }

  let(:nominee_a1) { create(:nominee, season_category: sc1) }
  let(:nominee_a2) { create(:nominee, season_category: sc1) }
  let(:nominee_b1) { create(:nominee, season_category: sc2) }
  let(:nominee_b2) { create(:nominee, season_category: sc2) }

  let(:user1) { create(:user, display_name: "Alice") }
  let(:user2) { create(:user, display_name: "Bob") }
  let(:player1) { create(:player, user: user1, season: season) }
  let(:player2) { create(:player, user: user2, season: season) }

  before do
    create(:pick_selection, player: player1, season_category: sc1, pick_type: think_type, nominee: nominee_a1)
    create(:pick_selection, player: player1, season_category: sc1, pick_type: want_type, nominee: nominee_a1)
    create(:pick_selection, player: player1, season_category: sc2, pick_type: think_type, nominee: nominee_b2)
    create(:pick_selection, player: player1, season_category: sc2, pick_type: want_type, nominee: nominee_b2)

    create(:pick_selection, player: player2, season_category: sc1, pick_type: think_type, nominee: nominee_a1)
    create(:pick_selection, player: player2, season_category: sc1, pick_type: want_type, nominee: nominee_a2)
    create(:pick_selection, player: player2, season_category: sc2, pick_type: think_type, nominee: nominee_b2)
    create(:pick_selection, player: player2, season_category: sc2, pick_type: want_type, nominee: nominee_b1)

    create(:winner, season_category: sc1, nominee: nominee_a1)
    create(:winner, season_category: sc2, nominee: nominee_b1)
  end

  subject { described_class.new(season).call }

  it "returns players sorted by total score descending" do
    expect(subject.map { |e| e[:player_name] }).to eq([ "Alice", "Bob" ])
  end

  it "calculates correct scores for player 1" do
    alice = subject.find { |e| e[:player_name] == "Alice" }
    think_score = alice[:pick_type_scores].find { |s| s[:pick_type_id] == think_type.id }[:score]
    want_score = alice[:pick_type_scores].find { |s| s[:pick_type_id] == want_type.id }[:score]

    expect(think_score).to eq(5)
    expect(want_score).to eq(2)
    expect(alice[:total_score]).to eq(7)
  end

  it "calculates correct scores for player 2" do
    bob = subject.find { |e| e[:player_name] == "Bob" }
    think_score = bob[:pick_type_scores].find { |s| s[:pick_type_id] == think_type.id }[:score]
    want_score = bob[:pick_type_scores].find { |s| s[:pick_type_id] == want_type.id }[:score]

    expect(think_score).to eq(5)
    expect(want_score).to eq(2)
    expect(bob[:total_score]).to eq(7)
  end
end
