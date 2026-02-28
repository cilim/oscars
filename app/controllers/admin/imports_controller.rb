module Admin
  class ImportsController < BaseController
    def create
      year = params[:year]
      file = Rails.root.join("db/data/#{year}.yml")

      unless File.exist?(file)
        redirect_to admin_seasons_path, alert: "No data file found for #{year}."
        return
      end

      data     = YAML.safe_load_file(file, permitted_classes: [ Symbol ])
      importer = SeasonImporter.new(data)
      season   = importer.call

      if season
        redirect_to admin_seasons_path,
                    notice: "Imported #{season.name} — #{data['categories'].length} categories."
      else
        redirect_to admin_seasons_path, alert: importer.errors.join(" ")
      end
    end
  end
end
