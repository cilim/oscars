require "base64"

class DatabaseBackupExporter
  FORMAT_VERSION = 1

  def initialize(schema: DatabaseBackupSchema.new)
    @schema = schema
  end

  def call
    {
      "format_version" => FORMAT_VERSION,
      "exported_at" => Time.current.iso8601,
      "tables" => schema.ordered_tables.to_h do |table_name|
        [ table_name, export_table(table_name) ]
      end
    }
  end

  private

  attr_reader :schema

  def export_table(table_name)
    binary_columns = schema.binary_columns_for(table_name)
    relation = schema.table_model(table_name).all
    primary_key = schema.table_model(table_name).primary_key

    relation = relation.order(primary_key) if primary_key.present?

    {
      "rows" => relation.map do |record|
        serialize_row(record.attributes, binary_columns)
      end
    }
  end

  def serialize_row(attributes, binary_columns)
    attributes.each_with_object({}) do |(column_name, value), serialized|
      serialized[column_name] = serialize_value(column_name, value, binary_columns)
    end
  end

  def serialize_value(column_name, value, binary_columns)
    return if value.nil?

    if binary_columns.include?(column_name)
      {
        "__type" => "base64",
        "value" => Base64.strict_encode64(value.to_s.b)
      }
    elsif value.respond_to?(:iso8601)
      value.iso8601(6)
    elsif value.is_a?(BigDecimal)
      value.to_s("F")
    else
      value
    end
  end
end
