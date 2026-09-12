class Nominee < ApplicationRecord
  belongs_to :season_category
  belongs_to :movie, autosave: true

  delegate :poster_url, :description, :imdb_url, to: :movie, allow_nil: true
  delegate :name, to: :movie, prefix: true, allow_nil: true

  after_destroy :destroy_movie_if_orphaned

  def display_name
    person_name.present? ? "#{person_name} — #{movie_name}" : movie_name
  end

  private

  def destroy_movie_if_orphaned
    return if movie_id.blank?

    associated_movie = Movie.find_by(id: movie_id)
    return if associated_movie.nil?

    associated_movie.destroy if associated_movie.nominees.where.not(id: id).none?
  end
end
