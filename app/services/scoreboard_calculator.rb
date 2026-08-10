class ScoreboardCalculator
  def initialize(season)
    @season = season
    @pick_types = season.scoring_scheme.pick_types.order(:display_order).to_a
  end

  def call
    winners = @season.season_categories
      .joins(:winner)
      .pluck("season_categories.id", "winners.nominee_id")
      .to_h

  @season.players
      .includes(:user, pick_selections: :pick_type)
      .map { |player| calculate_player_score(player, winners) }
      .sort_by { |entry| -entry[:total_score] }
  end

  private

  def calculate_player_score(player, winners)
    scores_by_type = @pick_types.index_with { 0 }

    player.pick_selections.each do |selection|
      winner_nominee_id = winners[selection.season_category_id]
      next unless winner_nominee_id

      scores_by_type[selection.pick_type] += selection.score_for(winner_nominee_id)
    end

    pick_type_scores = @pick_types.map do |pick_type|
      {
        pick_type_id: pick_type.id,
        emoji: pick_type.emoji,
        name: pick_type.name,
        score: scores_by_type[pick_type]
      }
    end

    {
      player_id: player.id,
      player_name: player.user.display_name,
      pick_type_scores: pick_type_scores,
      total_score: pick_type_scores.sum { |entry| entry[:score] }
    }
  end
end
