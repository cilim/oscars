require Rails.root.join("db/migrate/20260912120000_reconcile_international_movie_names")

RSpec.describe ReconcileInternationalMovieNames do
  subject(:migration) { described_class.new }

  let(:season) { create(:season) }

  around do |example|
    verbose = ActiveRecord::Migration.verbose
    ActiveRecord::Migration.verbose = false
    example.run
  ensure
    ActiveRecord::Migration.verbose = verbose
  end

  it "merges a country-suffixed duplicate into the canonical movie" do
    canonical = create(:movie, season: season, name: "Flow", description: "A cat, a dog, and a bird.")
    duplicate = create(:movie, season: season, name: "Flow Placeholder")
    duplicate.update_column(:name, "Flow (Latvia)")
    picture = create(:season_category, season: season, category: create(:category, name: "Best Animated Feature Film"))
    international = create(:season_category, season: season, category: create(:category, name: "Best International Feature Film"))
    picture_nom = create(:nominee, season_category: picture, movie: canonical)
    international_nom = create(:nominee, season_category: international, movie: duplicate)

    migration.up

    expect(Movie.where(season: season, name: "Flow").count).to eq(1)
    expect(Movie.find_by(season: season, name: "Flow (Latvia)")).to be_nil
    expect(picture_nom.reload.movie).to eq(canonical)
    expect(international_nom.reload.movie).to eq(canonical)
    expect(canonical.reload.description).to eq("A cat, a dog, and a bird.")
  end

  it "renames a suffixed movie when no canonical row exists" do
    movie = create(:movie, season: season, name: "Placeholder")
    movie.update_column(:name, "I'm Still Here (Brazil)")
    create(:nominee, season_category: create(:season_category, season: season), movie: movie)

    migration.up

    expect(movie.reload.name).to eq("I'm Still Here")
  end

  it "deletes movies that have no nominees" do
    create(:movie, season: season, name: "Orphan")

    migration.up

    expect(Movie.find_by(season: season, name: "Orphan")).to be_nil
  end
end
