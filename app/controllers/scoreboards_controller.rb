class ScoreboardsController < ApplicationController
  def show
    @season = Season.find(params[:season_id])
    @season_categories = @season.season_categories.includes(:category, :nominees, winner: :nominee)
    @scoreboard_data = ScoreboardCalculator.new(@season).call
    @is_admin = Current.user&.admin?
  end
end
