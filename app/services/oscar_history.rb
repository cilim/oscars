class OscarHistory
  PICTURE = "Best Picture"
  DIRECTOR = "Best Director"

  def call
    nights = announced_seasons.map { |season| night_for(season) }
    films = nights.flat_map { |night| night[:films] }

    { nights: nights.map { |night| night.except(:films) }, films: films }
  end

  private

  def announced_seasons
    season_ids = Winner.joins(:season_category).select("season_categories.season_id")

    Season
      .where(id: season_ids)
      .includes(season_categories: [ :category, { winner: { nominee: :movie } }, { nominees: :movie } ])
      .order(:year)
  end

  def night_for(season)
    tallies = Hash.new { |hash, movie_name| hash[movie_name] = { movie: movie_name, nominations: 0, wins: 0 } }
    picture_movie = nil
    director_movie = nil

    season.season_categories.each do |season_category|
      season_category.nominees.each do |nominee|
        movie_name = nominee.movie&.name
        next if movie_name.blank?

        tallies[movie_name][:nominations] += 1
      end

      winning_movie = season_category.winner&.nominee&.movie&.name
      next if winning_movie.blank?

      tallies[winning_movie][:wins] += 1

      case season_category.category_name
      when PICTURE then picture_movie = winning_movie
      when DIRECTOR then director_movie = winning_movie
      end
    end

    films = tallies.values
      .map { |tally| tally.merge(year: season.year) }
      .sort_by { |tally| [ -tally[:wins], -tally[:nominations], tally[:movie] ] }

    winning_films = films.select { |film| film[:wins].positive? }
    leader = winning_films.first
    picture_wins = picture_movie && tallies[picture_movie] ? tallies[picture_movie][:wins] : 0

    {
      year: season.year,
      season_name: season.name,
      award_count: winning_films.sum { |film| film[:wins] },
      unique_winning_films: winning_films.size,
      leader: leader ? { movie: leader[:movie], wins: leader[:wins] } : nil,
      picture: picture_movie ? { movie: picture_movie, wins: picture_wins } : nil,
      split: picture_movie.present? && leader.present? && picture_movie != leader[:movie],
      director_movie: director_movie,
      picture_director_split: picture_movie.present? && director_movie.present? && picture_movie != director_movie,
      films: films
    }
  end
end
