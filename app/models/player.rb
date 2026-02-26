class Player < ApplicationRecord
  belongs_to :user
  belongs_to :season
  has_many :picks, dependent: :destroy

  validates :user_id, uniqueness: { scope: :season_id }

  delegate :display_name, to: :user
end
