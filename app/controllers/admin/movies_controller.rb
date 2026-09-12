module Admin
  class MoviesController < BaseController
    before_action :set_season
    before_action :set_movie

    def edit
      load_tmdb_suggestion
    end

    def update
      if @movie.update(movie_params)
        redirect_to admin_season_path(@season), notice: "Movie updated."
      else
        load_tmdb_suggestion
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def set_season
      @season = Season.find(params[:season_id])
    end

    def set_movie
      @movie = @season.movies.find(params[:id])
    end

    def movie_params
      params.require(:movie).permit(:name, :poster_url, :description, :imdb_url)
    end

    def load_tmdb_suggestion
      return if Rails.application.credentials.tmdb_access_token.blank?

      @tmdb_suggestion = TmdbMovieLookup.new.fetch(@movie.name)
    end
  end
end
