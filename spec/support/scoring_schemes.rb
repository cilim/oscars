RSpec.configure do |config|
  config.before(:suite) do
    next if ScoringScheme.exists?(name: "Classic")

    FactoryBot.create(:scoring_scheme, :classic)
  end
end
