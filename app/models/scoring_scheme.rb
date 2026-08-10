class ScoringScheme < ApplicationRecord
  has_many :pick_types, -> { order(:display_order) }, dependent: :destroy, inverse_of: :scoring_scheme
  has_many :seasons, dependent: :restrict_with_error

  accepts_nested_attributes_for :pick_types, allow_destroy: true, reject_if: :all_blank

  validates :name, presence: true, uniqueness: true

  def locked?
    PickSelection.joins(:pick_type).where(pick_types: { scoring_scheme_id: id }).exists?
  end

  def deletable?
    seasons.none? && !locked?
  end

  def assignable?
    pick_types.any?
  end
end
