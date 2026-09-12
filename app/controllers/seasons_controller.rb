class SeasonsController < ApplicationController
  def index
    @seasons = Season.active
  end

  def show
    @season = Season.includes(scoring_scheme: :pick_types).find(params[:id])
    @player = Current.user.players.find_by(season: @season)
    @season_categories = @season.season_categories.includes(:category, nominees: :movie, winner: { nominee: :movie })
    @pick_types = @season.scoring_scheme.pick_types.order(:display_order)
    @selections_by_category = build_selections_by_category
    @view = params[:view].to_s == "movies" ? :movies : :categories
    @movie_tallies = build_movie_tallies if @player && @view == :movies
  end

  private

  def build_selections_by_category
    return {} unless @player

    @player.pick_selections
      .includes(:nominee, :pick_type)
      .where(season_category_id: @season.season_category_ids)
      .group_by(&:season_category_id)
      .transform_values do |selections|
        selections.group_by(&:pick_type_id)
      end
  end

  def build_movie_tallies
    movies = {}

    @season_categories.each do |season_category|
      season_category.nominees.each do |nominee|
        movie = nominee.movie
        next if movie.blank?

        tally = movies[movie.id] ||= { movie: movie, nominations: [], win_count: 0 }
        won = season_category.winner&.nominee_id == nominee.id
        tally[:nominations] << {
          category_name: season_category.category_name,
          person_name: nominee.person_name,
          won: won,
          announced: season_category.winner.present?
        }
        tally[:win_count] += 1 if won
      end
    end

    movies.values.sort_by { |row| [ -row[:win_count], -row[:nominations].size, row[:movie].name.downcase ] }
  end
end
