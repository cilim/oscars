module Admin
  class MoviesController < BaseController
    before_action :set_season
    before_action :set_movie

    def edit
      load_tmdb_suggestion
    end

    def update
      attrs = movie_params
      submitted_name = attrs[:name].to_s.strip
      canonical_name = Movie.normalized_name(submitted_name)
      other = @season.movies.where.not(id: @movie.id).find_by(name: canonical_name)

      if other && submitted_name != canonical_name
        merge_into!(other, attrs.merge(name: canonical_name))
      elsif @movie.update(attrs)
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

    def merge_into!(canonical, attrs)
      Movie.merge_duplicate!(@movie, canonical)
      %i[poster_url description imdb_url].each do |attr|
        attrs.delete(attr) if attrs[attr].blank? && canonical.public_send(attr).present?
      end

      if canonical.update(attrs)
        redirect_to admin_season_path(@season), notice: "Movie updated."
      else
        @movie = canonical
        load_tmdb_suggestion
        render :edit, status: :unprocessable_entity
      end
    end

    def load_tmdb_suggestion
      return if Rails.application.credentials.tmdb_access_token.blank?

      @tmdb_suggestion = TmdbMovieLookup.new.fetch(@movie.name)
    end
  end
end
