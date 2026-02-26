class SeasonCategory < ApplicationRecord
  belongs_to :season
  belongs_to :category
  has_many :nominees, dependent: :destroy
  has_many :picks, dependent: :destroy
  has_one :winner, dependent: :destroy

  validates :category_id, uniqueness: { scope: :season_id }

  delegate :name, to: :category, prefix: true
  delegate :has_person, to: :category
end
