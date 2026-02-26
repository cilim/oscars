class SeasonsController < ApplicationController
  def index
    @seasons = Season.active
  end

  def show
    @season = Season.find(params[:id])
    @player = Current.user.players.find_by(season: @season)
  end
end
