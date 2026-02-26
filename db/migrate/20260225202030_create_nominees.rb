class CreateNominees < ActiveRecord::Migration[8.1]
  def change
    create_table :nominees do |t|
      t.references :season_category, null: false, foreign_key: true
      t.string :movie_name, null: false
      t.string :person_name

      t.timestamps
    end
  end
end
