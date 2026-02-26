class PicksController < ApplicationController
  before_action :set_season
  before_action :set_player
  before_action :ensure_not_locked

  def edit
    @season_categories = @season.season_categories.includes(:category, :nominees)
    @picks_by_category = @player.picks.index_by(&:season_category_id)
  end

  def update
    Pick.transaction do
      picks_params.each do |season_category_id, pick_attrs|
        pick = @player.picks.find_or_initialize_by(season_category_id: season_category_id)
        pick.update!(pick_attrs.permit(:think_will_win_id, :want_to_win_id))
      end
    end
    redirect_to season_path(@season), notice: "Picks saved!"
  rescue ActiveRecord::RecordInvalid
    flash.now[:alert] = "Error saving picks."
    @season_categories = @season.season_categories.includes(:category, :nominees)
    @picks_by_category = @player.picks.reload.index_by(&:season_category_id)
    render :edit, status: :unprocessable_entity
  end

  private

  def set_season
    @season = Season.find(params[:season_id])
  end

  def set_player
    @player = Current.user.players.find_by!(season: @season)
  rescue ActiveRecord::RecordNotFound
    redirect_to season_path(@season), alert: "You are not a player in this season."
  end

  def ensure_not_locked
    redirect_to season_path(@season), alert: "Picks are locked." if @season.locked?
  end

  def picks_params
    params.require(:picks)
  end
end
