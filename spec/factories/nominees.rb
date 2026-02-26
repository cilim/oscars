FactoryBot.define do
  factory :nominee do
    season_category
    sequence(:movie_name) { |n| "Movie #{n}" }
    person_name { nil }

    trait :with_person do
      sequence(:person_name) { |n| "Person #{n}" }
    end
  end
end
