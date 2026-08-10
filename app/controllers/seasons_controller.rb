class SeasonsController < ApplicationController
  def index
    @seasons = Season.active
  end

  def show
    @season = Season.includes(scoring_scheme: :pick_types).find(params[:id])
    @player = Current.user.players.find_by(season: @season)
    @season_categories = @season.season_categories.includes(:category, :nominees, winner: :nominee)
    @pick_types = @season.scoring_scheme.pick_types.order(:display_order)
    @selections_by_category = build_selections_by_category
  end

  private

  def build_selections_by_category
    return {} unless @player

    @player.pick_selections
      .includes(:nominee, :pick_type)
      .where(season_category_id: @season.season_category_ids)
      .group_by(&:season_category_id)
      .transform_values do |selections|
        selections.group_by(&:pick_type_id)
      end
  end
end
