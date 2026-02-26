class Season < ApplicationRecord
  has_many :season_categories, -> { order(:position) }, dependent: :destroy
  has_many :categories, through: :season_categories
  has_many :players, dependent: :destroy
  has_many :users, through: :players

  validates :name, presence: true, uniqueness: true
  validates :year, presence: true, uniqueness: true

  scope :active, -> { where(archived: false).order(year: :desc) }
end
