class Movie < ApplicationRecord
  belongs_to :season
  has_many :nominees, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :season_id }

  def modal_available?
    poster_url.present? || description.present? || imdb_url.present?
  end
end
