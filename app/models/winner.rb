class Winner < ApplicationRecord
  belongs_to :season_category
  belongs_to :nominee

  validates :season_category_id, uniqueness: true

  after_commit :broadcast_scoreboard_update

  private

  def broadcast_scoreboard_update
    season = season_category.season
    season_categories = season.season_categories.includes(:category, :nominees, winner: :nominee)
    scoreboard_data = ScoreboardCalculator.new(season).call

    # Broadcast to regular players (no admin controls)
    Turbo::StreamsChannel.broadcast_replace_to(
      "season_#{season.id}_scoreboard",
      target: "scoreboard",
      partial: "scoreboards/scoreboard",
      locals: { season: season, scoreboard_data: scoreboard_data, season_categories: season_categories, is_admin: false }
    )

    # Broadcast to admins (with winner selection dropdowns intact)
    Turbo::StreamsChannel.broadcast_replace_to(
      "season_#{season.id}_scoreboard_admin",
      target: "scoreboard",
      partial: "scoreboards/scoreboard",
      locals: { season: season, scoreboard_data: scoreboard_data, season_categories: season_categories, is_admin: true }
    )
  end
end
