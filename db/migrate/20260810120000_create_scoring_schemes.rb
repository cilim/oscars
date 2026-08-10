class CreateScoringSchemes < ActiveRecord::Migration[8.1]
  def change
    create_table :scoring_schemes do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :scoring_schemes, :name, unique: true

    create_table :pick_types do |t|
      t.references :scoring_scheme, null: false, foreign_key: true
      t.string :name, null: false
      t.string :emoji, null: false
      t.integer :points_on_correct, null: false, default: 0
      t.integer :points_on_incorrect, null: false, default: 0
      t.integer :display_order, null: false, default: 0
      t.string :color, null: false
      t.boolean :allow_multiple_selections, null: false, default: false
      t.integer :max_selections

      t.timestamps
    end

    add_reference :seasons, :scoring_scheme, foreign_key: true

    create_table :pick_selections do |t|
      t.references :player, null: false, foreign_key: true
      t.references :season_category, null: false, foreign_key: true
      t.references :pick_type, null: false, foreign_key: true
      t.references :nominee, null: false, foreign_key: true

      t.timestamps
    end

    add_index :pick_selections,
              %i[player_id season_category_id pick_type_id nominee_id],
              unique: true,
              name: "index_pick_selections_unique_per_nominee"
  end
end
