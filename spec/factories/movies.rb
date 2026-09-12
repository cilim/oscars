FactoryBot.define do
  factory :movie do
    season
    sequence(:name) { |n| "Movie #{n}" }
    poster_url { nil }
    description { nil }
    imdb_url { nil }
  end
end
