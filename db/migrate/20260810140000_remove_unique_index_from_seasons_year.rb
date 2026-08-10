class RemoveUniqueIndexFromSeasonsYear < ActiveRecord::Migration[8.0]
  def change
    remove_index :seasons, :year
    add_index :seasons, :year
  end
end
