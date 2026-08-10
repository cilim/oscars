class PickType < ApplicationRecord
  belongs_to :scoring_scheme, inverse_of: :pick_types
  has_many :pick_selections, dependent: :restrict_with_error

  validates :name, :emoji, :display_order, :color, presence: true
  validates :points_on_correct, :points_on_incorrect, presence: true
  validates :max_selections, numericality: { only_integer: true, greater_than_or_equal_to: 2 }, allow_nil: true
  validate :at_least_one_nonzero_point
  validate :max_selections_when_multi_select

  before_validation :clear_max_selections_for_single_select

  def single_select?
    !allow_multiple_selections?
  end

  def formatted_points_on_correct
    format_points(points_on_correct)
  end

  def formatted_points_on_incorrect
    format_points(points_on_incorrect)
  end

  def risky?
    points_on_correct.negative? || points_on_incorrect.positive?
  end

  private

  def at_least_one_nonzero_point
    return if points_on_correct.nil? || points_on_incorrect.nil?

    if points_on_correct.zero? && points_on_incorrect.zero?
      errors.add(:base, "At least one point value must be non-zero")
    end
  end

  def max_selections_when_multi_select
    if allow_multiple_selections?
      if max_selections.blank?
        errors.add(:max_selections, "is required when multiple selections are allowed")
      elsif max_selections < 2
        errors.add(:max_selections, "must be at least 2")
      end
    elsif max_selections.present?
      errors.add(:max_selections, "must be blank for single-select pick types")
    end
  end

  def clear_max_selections_for_single_select
    self.max_selections = nil unless allow_multiple_selections?
  end

  def format_points(value)
    return "0" if value.zero?

    value.positive? ? "+#{value}" : value.to_s
  end
end
