class ScoreboardsController < ApplicationController
  before_action :require_locked

  def show
    @season_categories = @season.season_categories.includes(:category, :nominees, winner: :nominee, picks: { player: :user })
    @scoreboard_data = ScoreboardCalculator.new(@season).call
    @is_admin = Current.user&.admin?
  end

  private

  def require_locked
    @season = Season.find(params[:season_id])
    unless @season.locked?
      redirect_to season_path(@season), alert: "The scoreboard is available once picks are locked."
    end
  end
end
