RSpec.describe OscarHistory do
  def nominate(season, category_name, movie_name)
    category = Category.find_or_create_by!(name: category_name)
    sc = season.season_categories.find_by(category: category) ||
         create(:season_category, season: season, category: category)
    create(:nominee, season_category: sc, movie_name: movie_name)
  end

  def announce(season, category_name, movie_name)
    nominee = nominate(season, category_name, movie_name)
    create(:winner, season_category: nominee.season_category, nominee: nominee)
    nominee
  end

  describe "#call" do
    it "returns no nights when no winners have been announced" do
      create(:season)
      payload = described_class.new.call

      expect(payload[:nights]).to eq([])
      expect(payload[:films]).to eq([])
    end

    it "skips seasons that have nominees but no winners" do
      empty = create(:season, year: 2021, name: "93rd")
      nominate(empty, "Best Picture", "Nomadland")
      filled = create(:season, year: 2022, name: "94th")
      announce(filled, "Best Picture", "CODA")

      nights = described_class.new.call[:nights]
      expect(nights.map { |n| n[:year] }).to eq([ 2022 ])
    end

    it "counts wins per film and names the night's hog" do
      season = create(:season, year: 2023, name: "95th")
      announce(season, "Best Picture", "Everything Everywhere All at Once")
      announce(season, "Best Director", "Everything Everywhere All at Once")
      announce(season, "Best Actress", "Everything Everywhere All at Once")
      announce(season, "Best Actor", "The Whale")

      night = described_class.new.call[:nights].sole
      expect(night[:season_id]).to eq(season.id)
      expect(night[:year]).to eq(2023)
      expect(night[:award_count]).to eq(4)
      expect(night[:unique_winning_films]).to eq(2)
      expect(night[:leader]).to eq(movie: "Everything Everywhere All at Once", wins: 3)
      expect(night[:picture]).to eq(movie: "Everything Everywhere All at Once", wins: 3)
      expect(night[:split]).to be(false)
    end

    it "flags nights when Best Picture did not lead the board" do
      season = create(:season, year: 2022, name: "94th")
      announce(season, "Best Picture", "CODA")
      announce(season, "Best Supporting Actor", "CODA")
      announce(season, "Best Director", "The Power of the Dog")
      announce(season, "Best Cinematography", "Dune")
      announce(season, "Best Sound", "Dune")
      announce(season, "Best Visual Effects", "Dune")

      night = described_class.new.call[:nights].sole
      expect(night[:picture]).to eq(movie: "CODA", wins: 2)
      expect(night[:leader]).to eq(movie: "Dune", wins: 3)
      expect(night[:split]).to be(true)
      expect(night[:director_movie]).to eq("The Power of the Dog")
      expect(night[:picture_director_split]).to be(true)
    end

    it "counts every announced winner in a season" do
      season = create(:season, year: 2022, name: "94th")
      picture = create(:season_category, season: season, category: create(:category, name: "Best Picture"))
      sound = create(:season_category, season: season, category: create(:category, name: "Best Sound"))
      coda = create(:nominee, season_category: picture, movie_name: "CODA")
      dune = create(:nominee, season_category: sound, movie_name: "Dune")
      create(:winner, season_category: picture, nominee: coda)
      create(:winner, season_category: sound, nominee: dune)

      night = described_class.new.call[:nights].sole
      expect(Winner.count).to eq(2)
      expect(night[:award_count]).to eq(2)
      expect(night[:unique_winning_films]).to eq(2)
    end

    it "orders nights by year" do
      later = create(:season, year: 2024, name: "96th")
      earlier = create(:season, year: 2018, name: "90th")
      announce(later, "Best Picture", "Oppenheimer")
      announce(earlier, "Best Picture", "The Shape of Water")

      expect(described_class.new.call[:nights].map { |n| n[:year] }).to eq([ 2018, 2024 ])
    end

    it "tallies nominations vs wins per film" do
      season = create(:season, year: 2025, name: "97th")
      announce(season, "Best Picture", "Anora")
      announce(season, "Best Director", "Anora")
      nominate(season, "Best Film Editing", "Anora")
      nominate(season, "Best Picture", "The Brutalist")
      nominate(season, "Best Actor", "The Brutalist")
      nominate(season, "Best Director", "The Brutalist")

      films = described_class.new.call[:films]
      anora = films.find { |f| f[:movie] == "Anora" }
      brutalist = films.find { |f| f[:movie] == "The Brutalist" }

      expect(anora).to include(season_id: season.id, year: 2025, nominations: 3, wins: 2)
      expect(brutalist).to include(season_id: season.id, year: 2025, nominations: 3, wins: 0)
    end
  end
end
