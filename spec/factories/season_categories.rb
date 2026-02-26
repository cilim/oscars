FactoryBot.define do
  factory :season_category do
    season
    category
    position { 0 }
  end
end
