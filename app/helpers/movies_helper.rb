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

  def statuette_image(size: :md)
    css = size == :sm ? "statuette statuette--sm" : "statuette"
    image_tag "statuette.png", alt: "", class: css, aria: { hidden: true }
  end
end
