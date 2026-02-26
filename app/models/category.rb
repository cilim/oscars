class Category < ApplicationRecord
  has_many :season_categories, dependent: :destroy
  has_many :seasons, through: :season_categories

  validates :name, presence: true, uniqueness: true
end
