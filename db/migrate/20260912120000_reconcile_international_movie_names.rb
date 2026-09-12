class ReconcileInternationalMovieNames < ActiveRecord::Migration[8.1]
  def up
    country_names = load_country_names

    select_all("SELECT id, season_id, name, poster_url, description, imdb_url FROM movies").each do |movie|
      next unless row_exists?("movies", movie["id"])

      canonical_name = normalized_name(movie["name"], country_names)
      next if movie["name"] == canonical_name

      target = select_one(<<~SQL.squish)
        SELECT id, poster_url, description, imdb_url FROM movies
        WHERE season_id = #{movie["season_id"].to_i}
          AND id <> #{movie["id"].to_i}
          AND name = #{quote(canonical_name)}
      SQL

      if target
        merge_duplicate(movie, target)
      else
        execute(<<~SQL.squish)
          UPDATE movies
          SET name = #{quote(canonical_name)}, updated_at = #{quote(Time.current)}
          WHERE id = #{movie["id"].to_i}
        SQL
      end
    end

    execute(<<~SQL.squish)
      DELETE FROM movies
      WHERE NOT EXISTS (
        SELECT 1 FROM nominees WHERE nominees.movie_id = movies.id
      )
    SQL
  end

  def down
    # Country suffixes cannot be restored once stripped.
  end

  private

  def load_country_names
    YAML.load_file(Rails.root.join("config/oscar_country_names.yml"))
        .to_set { |name| name.to_s.strip.downcase }
  end

  def normalized_name(raw, country_names)
    name = raw.to_s.strip
    return name if name.blank?

    match = name.match(/\A(.*)\s+\(([^)]+)\)\z/)
    return name unless match

    title = match[1].strip
    suffix = match[2].strip
    country_suffix?(suffix, country_names) ? title : name
  end

  def country_suffix?(text, country_names)
    candidate = text.to_s.strip.downcase
    return false if candidate.blank?

    country_names.include?(candidate) || country_names.include?(candidate.delete_prefix("the ").strip)
  end

  def merge_duplicate(duplicate, canonical)
    %w[poster_url description imdb_url].each do |attr|
      next if canonical[attr].present? || duplicate[attr].blank?

      execute(<<~SQL.squish)
        UPDATE movies
        SET #{attr} = #{quote(duplicate[attr])}, updated_at = #{quote(Time.current)}
        WHERE id = #{canonical["id"].to_i}
      SQL
    end

    execute(<<~SQL.squish)
      UPDATE nominees
      SET movie_id = #{canonical["id"].to_i}
      WHERE movie_id = #{duplicate["id"].to_i}
    SQL

    execute("DELETE FROM movies WHERE id = #{duplicate['id'].to_i}")
  end

  def row_exists?(table, id)
    select_value("SELECT 1 FROM #{table} WHERE id = #{id.to_i}").present?
  end
end
