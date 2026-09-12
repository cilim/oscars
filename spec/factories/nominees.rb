FactoryBot.define do
  factory :nominee do
    transient do
      movie_name { nil }
      poster_url { nil }
      description { nil }
      imdb_url { nil }
    end

    season_category
    person_name { nil }

    after(:build) do |nominee, evaluator|
      season = nominee.season_category.season
      name = evaluator.movie_name.presence

      if nominee.movie.present? && name.nil? && evaluator.poster_url.nil? &&
         evaluator.description.nil? && evaluator.imdb_url.nil?
        nominee.movie.season = season unless nominee.movie.season_id == season.id
        next
      end

      movie = if name
        season.movies.find { |record| record.name == name } ||
          Movie.find_by(season_id: season.id, name: name) ||
          season.movies.build(name: name)
      else
        nominee.movie || season.movies.build(name: "Movie #{SecureRandom.hex(3)}")
      end

      movie.poster_url = evaluator.poster_url unless evaluator.poster_url.nil?
      movie.description = evaluator.description unless evaluator.description.nil?
      movie.imdb_url = evaluator.imdb_url unless evaluator.imdb_url.nil?
      nominee.movie = movie
    end

    trait :with_person do
      sequence(:person_name) { |n| "Person #{n}" }
    end
  end
end
