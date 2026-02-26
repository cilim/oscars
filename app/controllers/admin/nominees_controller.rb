module Admin
  class NomineesController < BaseController
    before_action :set_season
    before_action :set_season_category
    before_action :set_nominee, only: [ :edit, :update, :destroy ]

    def new
      @nominee = @season_category.nominees.new
    end

    def create
      @nominee = @season_category.nominees.new(nominee_params)
      if @nominee.save
        redirect_to admin_season_path(@season), notice: "Nominee added."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @nominee.update(nominee_params)
        redirect_to admin_season_path(@season), notice: "Nominee updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @nominee.destroy!
      redirect_to admin_season_path(@season), notice: "Nominee removed."
    end

    private

    def set_season
      @season = Season.find(params[:season_id])
    end

    def set_season_category
      @season_category = @season.season_categories.find(params[:season_category_id])
    end

    def set_nominee
      @nominee = @season_category.nominees.find(params[:id])
    end

    def nominee_params
      params.require(:nominee).permit(:movie_name, :person_name, :poster_url)
    end
  end
end
