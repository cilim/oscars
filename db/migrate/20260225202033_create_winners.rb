class CreateWinners < ActiveRecord::Migration[8.1]
  def change
    create_table :winners do |t|
      t.references :season_category, null: false, foreign_key: true, index: { unique: true }
      t.references :nominee, null: false, foreign_key: true

      t.timestamps
    end
  end
end
