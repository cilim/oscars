module Admin
  class SeasonCategoriesController < BaseController
    before_action :set_season

    def create
      position = @season.season_categories.maximum(:position).to_i + 1
      @season_category = @season.season_categories.new(season_category_params.merge(position: position))
      if @season_category.save
        redirect_to admin_season_path(@season), notice: "Category added to season."
      else
        redirect_to admin_season_path(@season), alert: "Could not add category."
      end
    end

    def destroy
      @season_category = @season.season_categories.find(params[:id])
      @season_category.destroy!
      redirect_to admin_season_path(@season), notice: "Category removed from season."
    end

    private

    def set_season
      @season = Season.find(params[:season_id])
    end

    def season_category_params
      params.require(:season_category).permit(:category_id)
    end
  end
end
