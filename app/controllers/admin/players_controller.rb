module Admin
  class PlayersController < BaseController
    before_action :set_season

    def create
      @player = @season.players.new(player_params)
      if @player.save
        redirect_to admin_season_path(@season), notice: "Player added."
      else
        redirect_to admin_season_path(@season), alert: "Could not add player."
      end
    end

    def destroy
      @player = @season.players.find(params[:id])
      @player.destroy!
      redirect_to admin_season_path(@season), notice: "Player removed."
    end

    private

    def set_season
      @season = Season.find(params[:season_id])
    end

    def player_params
      params.require(:player).permit(:user_id)
    end
  end
end
