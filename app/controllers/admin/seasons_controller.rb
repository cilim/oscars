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
      @season = Season.new(scoring_scheme_id: ScoringScheme.find_by(name: "Classic")&.id)
      load_form_options
    end

    def create
      @season = Season.new(season_params)
      if @season.save
        redirect_to admin_season_path(@season), notice: "Season created."
      else
        load_form_options
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      load_form_options
    end

    def update
      attrs = season_params
      if @season.scoring_scheme_locked?
        attrs = attrs.except(:scoring_scheme_id)
      end

      if @season.update(attrs)
        redirect_to admin_season_path(@season), notice: "Season updated."
      else
        load_form_options
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
      params.require(:season).permit(:name, :year, :locked, :archived, :scoring_scheme_id)
    end

    def load_form_options
      @assignable_scoring_schemes = ScoringScheme.includes(:pick_types).select(&:assignable?).sort_by(&:name)
    end
  end
end
