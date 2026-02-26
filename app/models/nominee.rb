class Nominee < ApplicationRecord
  belongs_to :season_category

  validates :movie_name, presence: true

  def display_name
    person_name.present? ? "#{person_name} — #{movie_name}" : movie_name
  end
end
