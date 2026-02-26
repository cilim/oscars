module Admin
  class SeasonsController < BaseController
    before_action :set_season, only: [ :show, :edit, :update, :destroy ]

    def index
      @seasons = Season.order(year: :desc)
    end

    def show
      @season_categories = @season.season_categories.includes(:category, :nominees, :winner)
      @available_categories = Category.where.not(id: @season.category_ids).order(:name)
      @available_users = User.where.not(id: @season.user_ids).order(:display_name)
      @players = @season.players.includes(:user)
    end

    def new
      @season = Season.new
    end

    def create
      @season = Season.new(season_params)
      if @season.save
        redirect_to admin_season_path(@season), notice: "Season created."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @season.update(season_params)
        redirect_to admin_season_path(@season), notice: "Season updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @season.destroy!
      redirect_to admin_seasons_path, notice: "Season deleted."
    end

    private

    def set_season
      @season = Season.find(params[:id])
    end

    def season_params
      params.require(:season).permit(:name, :year, :locked, :archived)
    end
  end
end
