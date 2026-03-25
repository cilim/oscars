module Admin
  class DatabaseBackupsController < BaseController
    def show
      backup = DatabaseBackupExporter.new.call

      send_data JSON.pretty_generate(backup),
                filename: "oscars-backup-#{Time.current.strftime('%Y%m%d-%H%M%S')}.json",
                type: "application/json; charset=utf-8",
                disposition: "attachment"
    end

    def import
      file = params[:backup_file]

      if file.blank?
        redirect_to admin_seasons_path, alert: "Choose a backup JSON file to import."
        return
      end

      importer = DatabaseBackupImporter.new(JSON.parse(file.read))

      if importer.call
        redirect_to admin_seasons_path,
                    notice: "Backup imported. Restored #{importer.imported_rows_count} rows across #{importer.imported_tables_count} tables."
      else
        redirect_to admin_seasons_path, alert: importer.errors.join(" ")
      end
    rescue JSON::ParserError
      redirect_to admin_seasons_path, alert: "Backup file is not valid JSON."
    end
  end
end
