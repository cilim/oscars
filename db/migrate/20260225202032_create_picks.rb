class CreatePicks < ActiveRecord::Migration[8.1]
  def change
    create_table :picks do |t|
      t.references :player, null: false, foreign_key: true
      t.references :season_category, null: false, foreign_key: true
      t.references :think_will_win, foreign_key: { to_table: :nominees }
      t.references :want_to_win, foreign_key: { to_table: :nominees }

      t.timestamps
    end
    add_index :picks, [ :player_id, :season_category_id ], unique: true
  end
end
