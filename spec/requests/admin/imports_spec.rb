require "rails_helper"

RSpec.describe "Admin::Imports", type: :request do
  let(:admin) { create(:user, :admin) }
  before { sign_in(admin) }

  let(:yaml_data) do
    {
      "season"     => { "name" => "97th Academy Awards (2025)", "year" => 2025 },
      "categories" => [
        {
          "name"       => "Best Picture",
          "has_person" => false,
          "nominees"   => [ { "movie" => "Anora", "person" => nil, "poster_url" => nil } ]
        }
      ]
    }
  end

  describe "POST /admin/import/:year" do
    context "when the data file exists" do
      before do
        allow(File).to receive(:exist?).and_call_original
        allow(File).to receive(:exist?).with(Rails.root.join("db/data/2025.yml")).and_return(true)
        allow(YAML).to receive(:safe_load_file).and_return(yaml_data)
      end

      it "creates a season and redirects with notice" do
        expect { post admin_import_path(2025) }.to change(Season, :count).by(1)
        expect(response).to redirect_to(admin_seasons_path)
        expect(flash[:notice]).to include("Imported")
      end

      context "when the importer fails" do
        before do
          importer = instance_double(SeasonImporter, call: nil, errors: ["Something went wrong"])
          allow(SeasonImporter).to receive(:new).and_return(importer)
        end

        it "redirects with an alert" do
          post admin_import_path(2025)
          expect(response).to redirect_to(admin_seasons_path)
          expect(flash[:alert]).to include("Something went wrong")
        end
      end
    end

    context "when the data file does not exist" do
      it "redirects with an alert" do
        post admin_import_path(9999)
        expect(response).to redirect_to(admin_seasons_path)
        expect(flash[:alert]).to include("No data file found")
      end
    end
  end
end
