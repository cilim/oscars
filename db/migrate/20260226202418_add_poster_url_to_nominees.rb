class AddPosterUrlToNominees < ActiveRecord::Migration[8.1]
  def change
    add_column :nominees, :poster_url, :string
  end
end
