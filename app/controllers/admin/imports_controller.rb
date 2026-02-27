module Admin
  class ImportsController < BaseController
    def create
      year = params[:year]
      file = Rails.root.join("db/data/#{year}.yml")

      unless File.exist?(file)
        redirect_to admin_seasons_path, alert: "No data file found for #{year}."
        return
      end

      data = YAML.safe_load_file(file, permitted_classes: [Symbol])
      season_data = data["season"]
      categories_data = data["categories"]

      ActiveRecord::Base.transaction do
        season = Season.find_or_initialize_by(year: season_data["year"])
        season.name = season_data["name"]
        season.save!

        categories_data.each_with_index do |cat_data, position|
          category = Category.find_or_create_by!(name: cat_data["name"]) do |c|
            c.has_person = cat_data["has_person"]
          end

          sc = SeasonCategory.find_or_initialize_by(season: season, category: category)
          sc.position = position
          sc.save!

          (cat_data["nominees"] || []).each do |nom_data|
            nom = Nominee.find_or_initialize_by(
              season_category: sc,
              movie_name: nom_data["movie"],
              person_name: nom_data["person"]
            )
            nom.poster_url = nom_data["poster_url"] if nom_data["poster_url"].present?
            nom.save!
          end
        end
      end

      redirect_to admin_seasons_path, notice: "Imported #{season_data['name']} — #{categories_data.length} categories."
    end
  end
end
