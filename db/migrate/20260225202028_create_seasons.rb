class CreateSeasons < ActiveRecord::Migration[8.1]
  def change
    create_table :seasons do |t|
      t.string :name, null: false
      t.integer :year, null: false
      t.boolean :locked, default: false, null: false
      t.boolean :archived, default: false, null: false

      t.timestamps
    end
    add_index :seasons, :name, unique: true
    add_index :seasons, :year, unique: true
  end
end
