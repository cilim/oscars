require "base64"

class DatabaseBackupImporter
  class ImportError < StandardError; end

  attr_reader :errors, :imported_rows_count, :imported_tables_count

  def initialize(payload, schema: DatabaseBackupSchema.new)
    @payload = payload
    @schema = schema
    @errors = []
    @imported_rows_count = 0
    @imported_tables_count = 0
  end

  def call
    validate_payload!

    ApplicationRecord.transaction do
      ApplicationRecord.connection.disable_referential_integrity do
        purge_tables!
        import_tables!
      end
    end

    true
  rescue ImportError, ActiveRecord::ActiveRecordError, JSON::ParserError => error
    errors << error.message
    false
  end

  private

  attr_reader :payload, :schema

  def validate_payload!
    raise ImportError, "Backup file is invalid." unless payload.is_a?(Hash)
    raise ImportError, "Backup format version is not supported." unless payload["format_version"] == DatabaseBackupExporter::FORMAT_VERSION
    raise ImportError, "Backup file is missing table data." unless payload["tables"].is_a?(Hash)

    backup_tables = payload["tables"].keys.sort
    expected_tables = schema.exportable_tables.sort

    missing_tables = expected_tables - backup_tables
    extra_tables = backup_tables - expected_tables

    raise ImportError, "Backup file is missing tables: #{missing_tables.join(', ')}." if missing_tables.any?
    raise ImportError, "Backup file has unknown tables: #{extra_tables.join(', ')}." if extra_tables.any?

    schema.exportable_tables.each do |table_name|
      table_payload = payload.dig("tables", table_name)
      raise ImportError, "Backup data for #{table_name} is invalid." unless table_payload.is_a?(Hash)
      raise ImportError, "Backup rows for #{table_name} are invalid." unless table_payload["rows"].is_a?(Array)
    end
  end

  def purge_tables!
    quoted_tables = schema.exportable_tables.map do |table_name|
      ApplicationRecord.connection.quote_table_name(table_name)
    end

    ApplicationRecord.connection.execute(
      "TRUNCATE TABLE #{quoted_tables.join(', ')} RESTART IDENTITY CASCADE"
    )
  end

  def import_tables!
    schema.ordered_tables.each do |table_name|
      rows = payload.dig("tables", table_name, "rows")
      next if rows.empty?

      schema.table_model(table_name).insert_all!(
        rows.map { |row| deserialize_row(table_name, row) }
      )

      @imported_tables_count += 1
      @imported_rows_count += rows.length
      reset_primary_key_sequence(table_name)
    end
  end

  def deserialize_row(table_name, row)
    raise ImportError, "Backup row for #{table_name} is invalid." unless row.is_a?(Hash)

    columns = schema.columns_for(table_name)

    row.each_with_object({}) do |(column_name, value), attributes|
      raise ImportError, "Backup row for #{table_name} includes unknown column #{column_name}." unless columns.key?(column_name)

      attributes[column_name] = deserialize_value(columns[column_name], value)
    end
  end

  def deserialize_value(column, value)
    return if value.nil?

    return decode_binary_value(value) if column.type == :binary

    value
  end

  def decode_binary_value(value)
    unless value.is_a?(Hash) && value["__type"] == "base64" && value["value"].is_a?(String)
      raise ImportError, "Backup binary value is invalid."
    end

    Base64.strict_decode64(value["value"]).b
  rescue ArgumentError
    raise ImportError, "Backup binary value is invalid."
  end

  def reset_primary_key_sequence(table_name)
    return unless ApplicationRecord.connection.respond_to?(:reset_pk_sequence!)

    primary_key = schema.table_model(table_name).primary_key
    return if primary_key.blank?

    ApplicationRecord.connection.reset_pk_sequence!(table_name)
  end
end
