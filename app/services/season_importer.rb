class SeasonImporter
  attr_reader :errors

  def initialize(data)
    @data   = data
    @errors = []
  end

  def call
    season_data    = @data["season"]
    categories_data = @data["categories"] || []

    ActiveRecord::Base.transaction do
      season = Season.find_or_initialize_by(year: season_data["year"])
      season.name = season_data["name"]
      season.save!

      categories_data.each_with_index do |cat_data, position|
        next if cat_data["name"].blank?

        category = Category.find_or_create_by!(name: cat_data["name"]) do |c|
          c.has_person = cat_data["has_person"]
        end

        sc = SeasonCategory.find_or_initialize_by(season: season, category: category)
        sc.position = position
        sc.save!

        (cat_data["nominees"] || []).each do |nom_data|
          next if nom_data["movie"].blank?

          nom = Nominee.find_or_initialize_by(
            season_category: sc,
            movie_name:      nom_data["movie"],
            person_name:     nom_data["person"].presence
          )
          nom.poster_url = nom_data["poster_url"] if nom_data["poster_url"].present?
          nom.save!
        end
      end

      season
    end
  rescue ActiveRecord::RecordInvalid => e
    @errors << e.message
    nil
  end
end
