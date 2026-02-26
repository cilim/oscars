FactoryBot.define do
  factory :season do
    sequence(:name) { |n| "#{2024 + n} Oscars" }
    sequence(:year) { |n| 2024 + n }
    locked { false }
    archived { false }

    trait :locked do
      locked { true }
    end

    trait :archived do
      archived { true }
    end
  end
end
