module QueryCounter
  def capture_sql(&block)
    queries = []
    callback = lambda do |*args|
      payload = args.last
      sql = payload[:sql].to_s
      next if payload[:name] == "SCHEMA"
      next if sql.match?(/\A(?:BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/i)

      queries << sql
    end

    ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
    queries
  end
end

RSpec.configure do |config|
  config.include QueryCounter, type: :request
end
