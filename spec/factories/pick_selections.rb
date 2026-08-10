FactoryBot.define do
  factory :pick_selection do
    player
    season_category { association :season_category, season: player.season }
    pick_type { player.season.scoring_scheme.pick_types.order(:display_order).first }
    nominee { association :nominee, season_category: season_category }
  end
end
