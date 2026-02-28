module Admin
  class ScrapesController < BaseController
    def new
    end

    def create
      year = params[:year].to_i

      unless year.between?(1990, Time.current.year + 3)
        flash.now[:alert] = "Please enter a valid year (1990–#{Time.current.year + 3})."
        render :new, status: :unprocessable_entity
        return
      end

      scraper = OscarsScraper.new(year)
      @data   = scraper.call

      if @data
        render :preview
      else
        flash.now[:alert] = scraper.errors.join(" ")
        render :new, status: :unprocessable_entity
      end
    end

    def import
      data     = build_import_data
      importer = SeasonImporter.new(data)
      season   = importer.call

      if season
        redirect_to admin_season_path(season),
                    notice: "Imported #{season.name} — #{data['categories'].length} categories."
      else
        @data = data
        flash.now[:alert] = importer.errors.join(" ")
        render :preview, status: :unprocessable_entity
      end
    end

    private

    def build_import_data
      season_p   = params.require(:season).permit(:name, :year)
      categories = (params[:categories]&.to_unsafe_h&.values || []).map do |cat|
        nominees = (cat[:nominees]&.values || []).map do |nom|
          {
            "movie"      => nom[:movie].to_s.strip,
            "person"     => nom[:person].to_s.strip.presence,
            "poster_url" => nom[:poster_url].to_s.strip.presence
          }
        end.reject { |n| n["movie"].blank? }

        {
          "name"       => cat[:name].to_s.strip,
          "has_person" => cat[:has_person] == "1",
          "nominees"   => nominees
        }
      end.reject { |c| c["name"].blank? }

      {
        "season"     => { "name" => season_p[:name], "year" => season_p[:year].to_i },
        "categories" => categories
      }
    end
  end
end
