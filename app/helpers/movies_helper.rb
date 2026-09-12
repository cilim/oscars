module MoviesHelper
  def movie_poster_trigger_data(movie)
    return {} unless movie&.modal_available?

    {
      action: "click->movie-poster#show",
      poster_url: movie.poster_url.to_s,
      movie_title: movie.name,
      movie_description: movie.description.to_s,
      imdb_url: movie.imdb_url.to_s
    }
  end
end
