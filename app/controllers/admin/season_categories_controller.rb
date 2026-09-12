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
      @season.reload

      season_categories = @season.season_categories.includes(:category, nominees: :movie, winner: { nominee: :movie })
      @movies = season_categories.flat_map { |sc| sc.nominees.filter_map(&:movie) }.uniq.sort_by { |movie| movie.name.downcase }
      @available_categories = Category.where.not(id: @season.category_ids).order(:name)

      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to admin_season_path(@season), notice: "Category removed from season." }
      end
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
