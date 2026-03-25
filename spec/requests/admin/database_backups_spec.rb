require "rails_helper"

RSpec.describe "Admin::DatabaseBackups", type: :request do
  let(:admin) { create(:user, :admin) }

  before { sign_in(admin) }

  describe "GET /admin/database_backup" do
    it "downloads a full JSON backup" do
      season = create(:season, name: "97th Academy Awards", year: 2025)
      category = create(:category, name: "Best Picture", has_person: false)
      season_category = create(:season_category, season:, category:)
      nominee = create(:nominee, season_category:, movie_name: "Anora")

      get admin_database_backup_path

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("application/json")
      expect(response.headers["Content-Disposition"]).to include("attachment")

      payload = JSON.parse(response.body)

      expect(payload["format_version"]).to eq(1)
      expect(payload["tables"].keys).to include("users", "seasons", "categories", "season_categories", "nominees")
      expect(payload["tables"].keys).not_to include("schema_migrations", "ar_internal_metadata")
      expect(payload.dig("tables", "seasons", "rows")).to include(
        a_hash_including("id" => season.id, "name" => "97th Academy Awards", "year" => 2025)
      )
      expect(payload.dig("tables", "nominees", "rows")).to include(
        a_hash_including("id" => nominee.id, "movie_name" => "Anora")
      )
    end
  end

  describe "POST /admin/database_backup/import" do
    it "replaces current data with the uploaded backup" do
      season = create(:season, name: "97th Academy Awards", year: 2025)
      category = create(:category, name: "Best Picture", has_person: false)
      season_category = create(:season_category, season:, category:, position: 3)
      nominee = create(:nominee, season_category:, movie_name: "Anora")

      backup_payload = DatabaseBackupExporter.new.call

      stale_season = create(:season, name: "Temporary Season", year: 2026)
      create(:category, name: "Temporary Category")

      post import_admin_database_backup_path, params: {
        backup_file: uploaded_backup_file(backup_payload)
      }

      expect(response).to redirect_to(admin_seasons_path)
      expect(flash[:notice]).to include("Backup imported")
      expect(Season.exists?(stale_season.id)).to be(false)
      expect(Season.exists?(season.id)).to be(true)
      expect(Category.find_by(name: "Best Picture")).to be_present
      expect(Category.find_by(name: "Temporary Category")).to be_nil
      expect(SeasonCategory.find_by(id: season_category.id)&.position).to eq(3)
      expect(Nominee.find_by(id: nominee.id)&.movie_name).to eq("Anora")
    end

    it "resets primary key sequences for future inserts" do
      season = create(:season, name: "97th Academy Awards", year: 2025)
      backup_payload = DatabaseBackupExporter.new.call

      create(:season, name: "Temporary Season", year: 2026)

      post import_admin_database_backup_path, params: {
        backup_file: uploaded_backup_file(backup_payload)
      }

      new_season = create(:season, name: "98th Academy Awards", year: 2027)

      expect(new_season.id).to be > season.id
    end

    it "rejects invalid JSON" do
      post import_admin_database_backup_path, params: {
        backup_file: uploaded_raw_file("{not-valid-json")
      }

      expect(response).to redirect_to(admin_seasons_path)
      expect(flash[:alert]).to include("not valid JSON")
    end

    it "requires an uploaded file" do
      post import_admin_database_backup_path

      expect(response).to redirect_to(admin_seasons_path)
      expect(flash[:alert]).to include("Choose a backup JSON file")
    end
  end

  describe "as regular user" do
    let(:user) { create(:user) }

    before { sign_in(user) }

    it "redirects export requests to root" do
      get admin_database_backup_path

      expect(response).to redirect_to(root_path)
    end

    it "redirects import requests to root" do
      post import_admin_database_backup_path

      expect(response).to redirect_to(root_path)
    end
  end

  def uploaded_backup_file(payload)
    uploaded_raw_file(JSON.generate(payload))
  end

  def uploaded_raw_file(contents)
    file = Tempfile.new([ "backup", ".json" ])
    file.write(contents)
    file.rewind

    Rack::Test::UploadedFile.new(file.path, "application/json")
  end
end
