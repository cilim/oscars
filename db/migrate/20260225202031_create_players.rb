class CreatePlayers < ActiveRecord::Migration[8.1]
  def change
    create_table :players do |t|
      t.references :user, null: false, foreign_key: true
      t.references :season, null: false, foreign_key: true

      t.timestamps
    end
    add_index :players, [ :user_id, :season_id ], unique: true
  end
end
