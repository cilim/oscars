module Admin
  class ScoringSchemesController < BaseController
    before_action :set_scoring_scheme, only: %i[show edit update destroy]

    def index
      @scoring_schemes = ScoringScheme.includes(:pick_types, :seasons).order(:name)
    end

    def show
      redirect_to edit_admin_scoring_scheme_path(@scoring_scheme)
    end

    def new
      @scoring_scheme = ScoringScheme.new
    end

    def create
      @scoring_scheme = ScoringScheme.new(scoring_scheme_name_params)
      if @scoring_scheme.save
        redirect_to edit_admin_scoring_scheme_path(@scoring_scheme), notice: "Scoring scheme created. Add pick types below."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      if @scoring_scheme.locked?
        redirect_to edit_admin_scoring_scheme_path(@scoring_scheme), alert: "This scheme cannot be edited because player picks already reference it."
        return
      end

      if @scoring_scheme.update(scoring_scheme_params)
        redirect_to edit_admin_scoring_scheme_path(@scoring_scheme), notice: "Scoring scheme updated."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      unless @scoring_scheme.deletable?
        redirect_to admin_scoring_schemes_path, alert: destroy_blocked_reason
        return
      end

      @scoring_scheme.destroy!
      redirect_to admin_scoring_schemes_path, notice: "Scoring scheme deleted."
    end

    private

    def set_scoring_scheme
      @scoring_scheme = ScoringScheme.includes(:pick_types).find(params[:id])
    end

    def scoring_scheme_name_params
      params.require(:scoring_scheme).permit(:name)
    end

    def scoring_scheme_params
      params.require(:scoring_scheme).permit(
        :name,
        pick_types_attributes: %i[
          id name emoji points_on_correct points_on_incorrect display_order color
          allow_multiple_selections max_selections _destroy
        ]
      )
    end

    def destroy_blocked_reason
      if @scoring_scheme.seasons.any?
        "Cannot delete a scheme assigned to seasons."
      else
        "Cannot delete a scheme referenced by player picks."
      end
    end
  end
end
