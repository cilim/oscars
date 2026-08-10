class ScoreboardsController < ApplicationController
  before_action :require_locked

  def show
    @season_categories = @season.season_categories.includes(
      :category,
      :nominees,
      winner: :nominee,
      pick_selections: { player: :user, pick_type: :scoring_scheme }
    )
    @scoreboard_data = ScoreboardCalculator.new(@season).call
    @is_admin = Current.user&.admin?
  end

  private

  def require_locked
    @season = Season.includes(scoring_scheme: :pick_types).find(params[:season_id])
    unless @season.locked?
      redirect_to season_path(@season), alert: "The scoreboard is available once picks are locked."
    end
  end
end
