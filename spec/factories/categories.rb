FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }
    has_person { true }

    trait :film_only do
      has_person { false }
    end
  end
end
