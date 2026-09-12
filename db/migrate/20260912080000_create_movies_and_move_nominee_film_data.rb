class CreateMoviesAndMoveNomineeFilmData < ActiveRecord::Migration[8.1]
  def up
    create_table :movies do |t|
      t.references :season, null: false, foreign_key: true
      t.string :name, null: false
      t.string :poster_url
      t.text :description
      t.string :imdb_url
      t.timestamps
    end

    add_index :movies, [ :season_id, :name ], unique: true

    add_reference :nominees, :movie, foreign_key: true

    say_with_time "backfilling movies from nominees" do
      execute <<~SQL.squish
        INSERT INTO movies (season_id, name, poster_url, created_at, updated_at)
        SELECT sc.season_id,
               n.movie_name,
               MIN(n.poster_url),
               NOW(),
               NOW()
        FROM nominees n
        INNER JOIN season_categories sc ON sc.id = n.season_category_id
        GROUP BY sc.season_id, n.movie_name
      SQL

      execute <<~SQL.squish
        UPDATE nominees n
        SET movie_id = m.id
        FROM season_categories sc, movies m
        WHERE n.season_category_id = sc.id
          AND m.season_id = sc.season_id
          AND m.name = n.movie_name
      SQL
    end

    change_column_null :nominees, :movie_id, false
    remove_column :nominees, :movie_name, :string
    remove_column :nominees, :poster_url, :string
  end

  def down
    add_column :nominees, :movie_name, :string
    add_column :nominees, :poster_url, :string

    execute <<~SQL.squish
      UPDATE nominees n
      SET movie_name = m.name,
          poster_url = m.poster_url
      FROM movies m
      WHERE n.movie_id = m.id
    SQL

    change_column_null :nominees, :movie_name, false
    remove_reference :nominees, :movie, foreign_key: true
    drop_table :movies
  end
end
