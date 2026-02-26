class CreateSeasonCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :season_categories do |t|
      t.references :season, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.integer :position, null: false, default: 0

      t.timestamps
    end
    add_index :season_categories, [ :season_id, :category_id ], unique: true
  end
end
