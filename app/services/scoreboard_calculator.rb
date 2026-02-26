class ScoreboardCalculator
  def initialize(season)
    @season = season
  end

  def call
    winners = @season.season_categories
      .joins(:winner)
      .pluck("season_categories.id", "winners.nominee_id")
      .to_h

    @season.players
      .includes(:user, picks: :season_category)
      .map { |player| calculate_player_score(player, winners) }
      .sort_by { |entry| -entry[:total_score] }
  end

  private

  def calculate_player_score(player, winners)
    think_score = 0
    want_score = 0

    player.picks.each do |pick|
      winner_nominee_id = winners[pick.season_category_id]
      next unless winner_nominee_id

      think_score += 5 if pick.think_will_win_id == winner_nominee_id
      want_score += 2 if pick.want_to_win_id == winner_nominee_id
    end

    {
      player_id: player.id,
      player_name: player.user.display_name,
      think_score: think_score,
      want_score: want_score,
      total_score: think_score + want_score
    }
  end
end
