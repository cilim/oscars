class PicksController < ApplicationController
  before_action :set_season
  before_action :set_player
  before_action :ensure_not_locked
  before_action :set_pick_types

  def edit
    @season_categories = @season.season_categories.includes(:category, :nominees)
    @selections_by_category = build_selections_index
  end

  def update
    PickSelection.transaction do
      sync_pick_selections!
    end

    respond_to do |format|
      format.html { redirect_to season_path(@season), notice: "Picks saved!" }
      format.turbo_stream { head :no_content }
    end
  rescue ActiveRecord::RecordInvalid, ArgumentError
    respond_to do |format|
      format.html do
        flash.now[:alert] = "Error saving picks."
        @season_categories = @season.season_categories.includes(:category, :nominees)
        @selections_by_category = build_selections_index
        render :edit, status: :unprocessable_entity
      end
      format.turbo_stream { head :unprocessable_entity }
    end
  end

  private

  def set_season
    @season = Season.includes(scoring_scheme: :pick_types).find(params[:season_id])
  end

  def set_player
    @player = Current.user.players.find_by!(season: @season)
  rescue ActiveRecord::RecordNotFound
    redirect_to season_path(@season), alert: "You are not a player in this season."
  end

  def ensure_not_locked
    redirect_to season_path(@season), alert: "Picks are locked." if @season.locked?
  end

  def set_pick_types
    @pick_types = @season.scoring_scheme.pick_types.order(:display_order)
  end

  def build_selections_index
    @player.pick_selections
      .where(season_category_id: @season.season_category_ids)
      .group_by(&:season_category_id)
      .transform_values do |selections|
        selections.group_by(&:pick_type_id).transform_values { |rows| rows.map(&:nominee_id) }
      end
  end

  def sync_pick_selections!
    category_params = picks_params

    @season.season_category_ids.each do |season_category_id|
      type_params = category_params[season_category_id.to_s] || {}

      @pick_types.each do |pick_type|
        nominee_ids = extract_nominee_ids(type_params[pick_type.id.to_s])
        validate_nominee_selections!(pick_type, nominee_ids, season_category_id)

        scope = @player.pick_selections.where(
          season_category_id: season_category_id,
          pick_type_id: pick_type.id
        )

        scope.where.not(nominee_id: nominee_ids).destroy_all

        nominee_ids.each do |nominee_id|
          @player.pick_selections.find_or_create_by!(
            season_category_id: season_category_id,
            pick_type_id: pick_type.id,
            nominee_id: nominee_id
          )
        end
      end
    end
  end

  def extract_nominee_ids(raw)
    ids = case raw
    when ActionController::Parameters
      raw[:nominee_ids]
    when Hash
      raw[:nominee_ids] || raw["nominee_ids"]
    else
      raw
    end

    Array(ids).map(&:presence).compact.map(&:to_i).uniq
  end

  def validate_nominee_selections!(pick_type, nominee_ids, season_category_id)
    if pick_type.single_select? && nominee_ids.size > 1
      raise ArgumentError, "Only one selection allowed for #{pick_type.name}"
    end

    if pick_type.allow_multiple_selections? && nominee_ids.size > pick_type.max_selections
      raise ArgumentError, "Too many selections for #{pick_type.name}"
    end

    valid_nominee_ids = Nominee.where(season_category_id: season_category_id).pluck(:id)
    invalid = nominee_ids - valid_nominee_ids
    raise ArgumentError, "Invalid nominee selection" if invalid.any?
  end

  def picks_params
    params.fetch(:picks, {}).permit!
  end
end
