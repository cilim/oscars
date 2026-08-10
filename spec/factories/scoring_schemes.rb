FactoryBot.define do
  factory :scoring_scheme do
    sequence(:name) { |n| "Scheme #{n}" }

    trait :classic do
      name { "Classic" }

      after(:create) do |scheme|
        unless scheme.pick_types.exists?(display_order: 1)
          create(:pick_type, :think, scoring_scheme: scheme)
        end
        unless scheme.pick_types.exists?(display_order: 2)
          create(:pick_type, :want, scoring_scheme: scheme)
        end
      end
    end
  end
end
