class Season < ApplicationRecord
  belongs_to :scoring_scheme

  has_many :season_categories, -> { order(:position) }, dependent: :destroy
  has_many :categories, through: :season_categories
  has_many :players, dependent: :destroy
  has_many :users, through: :players

  validates :name, presence: true, uniqueness: true
  validates :year, presence: true

  scope :active, -> { where(archived: false).order(year: :desc) }

  def scoring_scheme_locked?
    PickSelection.joins(player: :season).where(players: { season_id: id }).exists?
  end
end
