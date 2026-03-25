class DatabaseBackupSchema
  INTERNAL_TABLES = %w[ar_internal_metadata schema_migrations].freeze

  def exportable_tables
    @exportable_tables ||= begin
      connection.tables
        .reject { |table| INTERNAL_TABLES.include?(table) }
        .sort
    end
  end

  def ordered_tables
    @ordered_tables ||= begin
      dependencies = exportable_tables.to_h do |table|
        [ table, connection.foreign_keys(table).map(&:to_table) & exportable_tables ]
      end

      incoming_counts = dependencies.transform_values(&:count)
      dependents = Hash.new { |hash, key| hash[key] = [] }

      dependencies.each do |table, parents|
        parents.each { |parent| dependents[parent] << table }
      end

      queue = incoming_counts.select { |_table, count| count.zero? }.keys.sort
      ordered = []

      until queue.empty?
        table = queue.shift
        ordered << table

        dependents[table].sort.each do |dependent|
          incoming_counts[dependent] -= 1
          queue << dependent if incoming_counts[dependent].zero?
        end

        queue.sort!
      end

      ordered + (exportable_tables - ordered)
    end
  end

  def table_model(table_name)
    table_models[table_name] ||= Class.new(ApplicationRecord) do
      self.table_name = table_name
      self.inheritance_column = :_type_disabled
    end
  end

  def columns_for(table_name)
    table_model(table_name).columns.index_by(&:name)
  end

  def binary_columns_for(table_name)
    columns_for(table_name)
      .values
      .select { |column| column.type == :binary }
      .map(&:name)
  end

  private

  def connection
    ApplicationRecord.connection
  end

  def table_models
    @table_models ||= {}
  end
end
