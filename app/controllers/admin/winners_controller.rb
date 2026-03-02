module Admin
  class WinnersController < BaseController
    before_action :set_season

    def create
      @winner = Winner.new(winner_params)
      if @winner.save
        respond_to do |format|
          format.html { redirect_to season_scoreboard_path(@season), notice: "Winner announced!", status: :see_other }
          format.turbo_stream do
            @season_category   = SeasonCategory.includes(:category, :nominees, winner: :nominee, picks: { player: :user }).find(@winner.season_category_id)
            @season_categories = @season.season_categories.includes(:winner)
            @scoreboard_data   = ScoreboardCalculator.new(@season).call
          end
        end
      else
        respond_to do |format|
          format.html { redirect_to season_scoreboard_path(@season), alert: "Error setting winner.", status: :see_other }
          format.turbo_stream { render turbo_stream: turbo_stream.replace("scoreboard-flash", partial: "scoreboards/flash_error") }
        end
      end
    end

    def destroy
      @winner = Winner.find(params[:id])
      @season_category_id = @winner.season_category_id
      @winner.destroy!
      respond_to do |format|
        format.html { redirect_to season_scoreboard_path(@season), notice: "Winner removed.", status: :see_other }
        format.turbo_stream do
          @season_category   = SeasonCategory.includes(:category, :nominees, winner: :nominee, picks: { player: :user }).find(@season_category_id)
          @season_categories = @season.season_categories.includes(:winner)
          @scoreboard_data   = ScoreboardCalculator.new(@season).call
        end
      end
    end

    private

    def set_season
      @season = Season.find(params[:season_id])
    end

    def winner_params
      params.require(:winner).permit(:season_category_id, :nominee_id)
    end
  end
end
