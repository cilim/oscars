FactoryBot.define do
  factory :pick_type do
    scoring_scheme
    name { "Think will win" }
    emoji { "🧠" }
    points_on_correct { 5 }
    points_on_incorrect { 0 }
    display_order { 1 }
    color { "#0ea5e9" }
    allow_multiple_selections { false }

    trait :think do
      name { "Think will win" }
      emoji { "🧠" }
      points_on_correct { 5 }
      points_on_incorrect { 0 }
      display_order { 1 }
      color { "#0ea5e9" }
    end

    trait :want do
      name { "Want to win" }
      emoji { "❤️" }
      points_on_correct { 2 }
      points_on_incorrect { 0 }
      display_order { 2 }
      color { "#8b5cf6" }
    end

    trait :multi do
      allow_multiple_selections { true }
      max_selections { 3 }
      points_on_correct { -100 }
      points_on_incorrect { 5 }
    end
  end
end
