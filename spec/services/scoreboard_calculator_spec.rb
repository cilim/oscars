require "rails_helper"

RSpec.describe ScoreboardCalculator do
  let(:season) { create(:season) }
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
    # Player 1: guesses both think and want correctly for sc1
    create(:pick, player: player1, season_category: sc1, think_will_win: nominee_a1, want_to_win: nominee_a1)
    # Player 1: guesses wrong for sc2
    create(:pick, player: player1, season_category: sc2, think_will_win: nominee_b2, want_to_win: nominee_b2)

    # Player 2: guesses think correctly, want wrong for sc1
    create(:pick, player: player2, season_category: sc1, think_will_win: nominee_a1, want_to_win: nominee_a2)
    # Player 2: guesses want correctly for sc2
    create(:pick, player: player2, season_category: sc2, think_will_win: nominee_b2, want_to_win: nominee_b1)

    # Winners
    create(:winner, season_category: sc1, nominee: nominee_a1)
    create(:winner, season_category: sc2, nominee: nominee_b1)
  end

  subject { described_class.new(season).call }

  it "returns players sorted by total score descending" do
    expect(subject.map { |e| e[:player_name] }).to eq([ "Alice", "Bob" ])
  end

  it "calculates correct scores for player 1" do
    alice = subject.find { |e| e[:player_name] == "Alice" }
    # sc1: think correct (5) + want correct (2) = 7
    # sc2: both wrong = 0
    expect(alice[:think_score]).to eq(5)
    expect(alice[:want_score]).to eq(2)
    expect(alice[:total_score]).to eq(7)
  end

  it "calculates correct scores for player 2" do
    bob = subject.find { |e| e[:player_name] == "Bob" }
    # sc1: think correct (5) + want wrong (0) = 5
    # sc2: think wrong (0) + want correct (2) = 2
    expect(bob[:think_score]).to eq(5)
    expect(bob[:want_score]).to eq(2)
    expect(bob[:total_score]).to eq(7)
  end
end
