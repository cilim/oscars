FactoryBot.define do
  factory :pick do
    player
    season_category
    think_will_win { nil }
    want_to_win { nil }
  end
end
