module Admin
  class SeasonsController < BaseController
    before_action :set_season, only: [ :show, :update, :destroy ]

    def index
      @seasons = Season.order(year: :desc)
    end

    def show
      load_show
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

    def update
      attrs = season_params
      attrs = attrs.except(:scoring_scheme_id) if @season.scoring_scheme_locked?

      if @season.update(attrs)
        load_form_options
        respond_to do |format|
          format.turbo_stream
          format.html { redirect_to admin_season_path(@season), notice: "Season updated." }
        end
      else
        respond_to do |format|
          format.turbo_stream { head :unprocessable_entity }
          format.html do
            load_show
            render :show, status: :unprocessable_entity
          end
        end
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

    def load_show
      @season_categories = @season.season_categories.includes(:category, nominees: :movie, winner: { nominee: :movie })
      @movies = movies_from(@season_categories)
      @available_categories = Category.where.not(id: @season.category_ids).order(:name)
      @available_users = User.where.not(id: @season.user_ids).order(:display_name)
      @players = @season.players.includes(:user)
      load_form_options
    end

    def movies_from(season_categories)
      season_categories.flat_map { |sc| sc.nominees.filter_map(&:movie) }.uniq.sort_by { |movie| movie.name.downcase }
    end

    def load_form_options
      @assignable_scoring_schemes = ScoringScheme.includes(:pick_types).select(&:assignable?).sort_by(&:name)
    end
  end
end
