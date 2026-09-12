module Admin
  class NomineesController < BaseController
    before_action :set_season
    before_action :set_season_category
    before_action :set_nominee, only: [ :edit, :update, :destroy ]

    def new
      @nominee = @season_category.nominees.new(movie: @season.movies.new)
    end

    def create
      @nominee = @season_category.nominees.new(person_name: nominee_params[:person_name].presence)
      previous_movie = nil
      assign_movie(@nominee)

      if save_nominee(@nominee, previous_movie)
        redirect_to admin_season_path(@season), notice: "Nominee added."
      else
        @nominee.movie ||= @season.movies.new(name: nominee_params[:movie_name])
        render :new, status: :unprocessable_entity
      end
    end

    def edit
    end

    def update
      previous_movie = @nominee.movie
      @nominee.person_name = nominee_params[:person_name].presence
      assign_movie(@nominee)

      if save_nominee(@nominee, previous_movie)
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
      params.require(:nominee).permit(:movie_name, :person_name, :poster_url, :description, :imdb_url)
    end

    def assign_movie(nominee)
      name = nominee_params[:movie_name].to_s.strip
      movie = @season.movies.find_or_initialize_by(name: name)
      apply_movie_attributes(movie, allow_blank: movie.new_record? || movie == nominee.movie)
      nominee.movie = movie
    end

    def apply_movie_attributes(movie, allow_blank:)
      %i[poster_url description imdb_url].each do |attr|
        next unless nominee_params.key?(attr)

        value = nominee_params[attr]
        if allow_blank
          movie[attr] = value.presence
        elsif value.present?
          movie[attr] = value
        end
      end
    end

    def save_nominee(nominee, previous_movie)
      ActiveRecord::Base.transaction do
        nominee.movie.save!
        nominee.save!
        if previous_movie && previous_movie != nominee.movie && previous_movie.nominees.reload.none?
          previous_movie.destroy!
        end
      end
      true
    rescue ActiveRecord::RecordInvalid
      false
    end
  end
end
