class MigratePicksToPickSelections < ActiveRecord::Migration[8.1]
  class MigrationScoringScheme < ActiveRecord::Base
    self.table_name = "scoring_schemes"
  end

  class MigrationPickType < ActiveRecord::Base
    self.table_name = "pick_types"
  end

  class MigrationPick < ActiveRecord::Base
    self.table_name = "picks"
  end

  class MigrationPickSelection < ActiveRecord::Base
    self.table_name = "pick_selections"
  end

  class MigrationSeason < ActiveRecord::Base
    self.table_name = "seasons"
  end

  def up
    classic_id = MigrationScoringScheme.create!(name: "Classic").id

    think_id = MigrationPickType.create!(
      scoring_scheme_id: classic_id,
      name: "Think will win",
      emoji: "🧠",
      points_on_correct: 5,
      points_on_incorrect: 0,
      display_order: 1,
      color: "#0ea5e9",
      allow_multiple_selections: false
    ).id

    want_id = MigrationPickType.create!(
      scoring_scheme_id: classic_id,
      name: "Want to win",
      emoji: "❤️",
      points_on_correct: 2,
      points_on_incorrect: 0,
      display_order: 2,
      color: "#8b5cf6",
      allow_multiple_selections: false
    ).id

    MigrationSeason.update_all(scoring_scheme_id: classic_id)

    MigrationPick.find_each do |pick|
      if pick.think_will_win_id.present?
        MigrationPickSelection.create!(
          player_id: pick.player_id,
          season_category_id: pick.season_category_id,
          pick_type_id: think_id,
          nominee_id: pick.think_will_win_id,
          created_at: pick.created_at,
          updated_at: pick.updated_at
        )
      end

      if pick.want_to_win_id.present?
        MigrationPickSelection.create!(
          player_id: pick.player_id,
          season_category_id: pick.season_category_id,
          pick_type_id: want_id,
          nominee_id: pick.want_to_win_id,
          created_at: pick.created_at,
          updated_at: pick.updated_at
        )
      end
    end

    remove_reference :picks, :think_will_win, foreign_key: { to_table: :nominees }
    remove_reference :picks, :want_to_win, foreign_key: { to_table: :nominees }
    drop_table :picks

    change_column_null :seasons, :scoring_scheme_id, false
  end

  def down
    create_table :picks do |t|
      t.references :player, null: false, foreign_key: true
      t.references :season_category, null: false, foreign_key: true
      t.bigint :think_will_win_id
      t.bigint :want_to_win_id

      t.timestamps
    end

    add_index :picks, %i[player_id season_category_id], unique: true
    add_index :picks, :think_will_win_id
    add_index :picks, :want_to_win_id
    add_foreign_key :picks, :nominees, column: :think_will_win_id
    add_foreign_key :picks, :nominees, column: :want_to_win_id

    classic = MigrationScoringScheme.find_by(name: "Classic")
    return unless classic

    think_type = MigrationPickType.find_by(scoring_scheme_id: classic.id, display_order: 1)
    want_type = MigrationPickType.find_by(scoring_scheme_id: classic.id, display_order: 2)

    MigrationPickSelection.find_each do |selection|
      pick = MigrationPick.find_or_initialize_by(
        player_id: selection.player_id,
        season_category_id: selection.season_category_id
      )

      if selection.pick_type_id == think_type&.id
        pick.think_will_win_id = selection.nominee_id
      elsif selection.pick_type_id == want_type&.id
        pick.want_to_win_id = selection.nominee_id
      end

      pick.save!
    end

    change_column_null :seasons, :scoring_scheme_id, true
    MigrationSeason.update_all(scoring_scheme_id: nil)

    drop_table :pick_selections
    remove_reference :seasons, :scoring_scheme, foreign_key: true
    drop_table :pick_types
    drop_table :scoring_schemes
  end
end
