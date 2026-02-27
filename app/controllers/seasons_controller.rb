class SeasonsController < ApplicationController
  def index
    @seasons = Season.active
  end

  def show
    @season = Season.find(params[:id])
    @player = Current.user.players.find_by(season: @season)
    @season_categories = @season.season_categories.includes(:category, :nominees, winner: :nominee)
    @picks_by_category = @player&.picks&.includes(:think_will_win, :want_to_win)&.index_by(&:season_category_id) || {}
  end
end
