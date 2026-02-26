class Pick < ApplicationRecord
  belongs_to :player
  belongs_to :season_category
  belongs_to :think_will_win, class_name: "Nominee", optional: true
  belongs_to :want_to_win, class_name: "Nominee", optional: true

  validates :season_category_id, uniqueness: { scope: :player_id }

  def think_score
    return 0 unless think_will_win_id && season_category.winner
    think_will_win_id == season_category.winner.nominee_id ? 5 : 0
  end

  def want_score
    return 0 unless want_to_win_id && season_category.winner
    want_to_win_id == season_category.winner.nominee_id ? 2 : 0
  end

  def total_score
    think_score + want_score
  end
end
