class PickSelection < ApplicationRecord
  belongs_to :player
  belongs_to :season_category
  belongs_to :pick_type
  belongs_to :nominee

  validates :nominee_id, uniqueness: { scope: %i[player_id season_category_id pick_type_id] }
  validate :nominee_belongs_to_season_category
  validate :pick_type_matches_season_scheme
  validate :respects_max_selections, on: :create

  def score_for(winner_nominee_id)
    return 0 unless winner_nominee_id

    if nominee_id == winner_nominee_id
      pick_type.points_on_correct
    else
      pick_type.points_on_incorrect
    end
  end

  private

  def nominee_belongs_to_season_category
    return if nominee_id.blank? || season_category_id.blank?

    unless Nominee.exists?(id: nominee_id, season_category_id: season_category_id)
      errors.add(:nominee, "must belong to this category")
    end
  end

  def pick_type_matches_season_scheme
    return if pick_type_id.blank? || season_category_id.blank?

    season_scheme_id = season_category&.season&.scoring_scheme_id
    return if season_scheme_id.blank?

    unless pick_type.scoring_scheme_id == season_scheme_id
      errors.add(:pick_type, "must belong to the season's scoring scheme")
    end
  end

  def respects_max_selections
    return if pick_type.blank? || player_id.blank? || season_category_id.blank?

    if pick_type.single_select?
      existing = PickSelection.where(
        player_id: player_id,
        season_category_id: season_category_id,
        pick_type_id: pick_type_id
      )
      existing = existing.where.not(id: id) if persisted?
      if existing.exists?
        errors.add(:base, "only one selection allowed for this pick type")
      end
    else
      count = PickSelection.where(
        player_id: player_id,
        season_category_id: season_category_id,
        pick_type_id: pick_type_id
      )
      count = count.where.not(id: id) if persisted?
      if count.count >= pick_type.max_selections
        errors.add(:base, "maximum selections reached for this pick type")
      end
    end
  end
end
