RSpec.describe HistoryHelper do
  describe "#hog_kicker" do
    it "calls out a raid when two films took seven" do
      nights = [
        { year: 2023, leader: { movie: "Everything Everywhere All at Once", wins: 7 } },
        { year: 2024, leader: { movie: "Oppenheimer", wins: 7 } }
      ]
      expect(helper.hog_kicker(nights)).to include("raid").and include("Oppenheimer").and include("Everything Everywhere All at Once")
    end

    it "contrasts the greediest night with the most generous" do
      nights = [
        { year: 2023, leader: { movie: "Everything Everywhere All at Once", wins: 7 } },
        { year: 2022, leader: { movie: "CODA", wins: 3 } }
      ]
      copy = helper.hog_kicker(nights)
      expect(copy).to include("2023: Everything Everywhere All at Once led with 7")
      expect(copy).to include("2022 passed the statue around")
      expect(copy).to include("CODA topped out at 3")
    end

    it "does not invent a contrast when there is only one night" do
      nights = [ { year: 2022, leader: { movie: "Dune", wins: 6 } } ]
      expect(helper.hog_kicker(nights)).to eq("2022: Dune led with 6.")
    end
  end

  describe "#heartbreak_kicker" do
    it "names the sharpest closer and the loudest snub" do
      films = [
        { year: 2025, movie: "Anora", nominations: 6, wins: 5 },
        { year: 2020, movie: "The Irishman", nominations: 10, wins: 0 }
      ]
      copy = helper.heartbreak_kicker(films)
      expect(copy).to include("Anora")
      expect(copy).to include("The Irishman")
      expect(copy).to include("10-for-0")
    end
  end

  describe "#picture_kicker" do
    it "narrates years when Picture did not lead" do
      nights = [
        {
          year: 2022,
          split: true,
          picture: { movie: "CODA", wins: 3 },
          leader: { movie: "Dune", wins: 6 }
        }
      ]
      expect(helper.picture_kicker(nights)).to include("CODA").and include("Dune")
    end
  end
end
