RSpec.describe OscarHistoryCharts do
  let(:nights) do
    [
      {
        year: 2021,
        season_name: "93rd",
        award_count: 19,
        unique_winning_films: 11,
        leader: { movie: "Nomadland", wins: 3 },
        picture: { movie: "Nomadland", wins: 3 },
        split: false,
        director_movie: "Nomadland",
        picture_director_split: false
      },
      {
        year: 2022,
        season_name: "94th",
        award_count: 19,
        unique_winning_films: 11,
        leader: { movie: "Dune", wins: 6 },
        picture: { movie: "CODA", wins: 3 },
        split: true,
        director_movie: "The Power of the Dog",
        picture_director_split: true
      }
    ]
  end

  let(:films) do
    [
      { year: 2025, movie: "Anora", nominations: 6, wins: 5 },
      { year: 2020, movie: "The Irishman", nominations: 10, wins: 0 },
      { year: 2022, movie: "Dune", nominations: 10, wins: 6 },
      { year: 2021, movie: "Minari", nominations: 4, wins: 1 }
    ]
  end

  subject(:charts) { described_class.new(nights: nights, films: films) }

  describe "#hog" do
    it "plots the leading film's haul for each year" do
      points = charts.hog.dig(:series, 0, :data)
      expect(points.map { |point| point[:y] }).to eq([ 3, 6 ])
      expect(points.map { |point| point[:film] }).to eq([ "Nomadland", "Dune" ])
    end
  end

  describe "#heartbreak" do
    it "plots well-nominated films as nomination/win pairs" do
      points = charts.heartbreak.dig(:series).flat_map { |series| series[:data] }
      names = points.map { |point| point[:name] }
      expect(names).to include("Anora (2025)", "The Irishman (2020)", "Dune (2022)")
      expect(names).not_to include("Minari (2021)")
      irishman = points.find { |point| point[:name].start_with?("The Irishman") }
      expect(irishman).to include(x: 10, y: 0)
    end
  end

  describe "#picture" do
    it "compares Best Picture's haul with the night's biggest winner" do
      series = charts.picture[:series]
      picture = series.find { |s| s[:name] == "Best Picture winner" }
      leader = series.find { |s| s[:name] == "Night's biggest winner" }
      expect(picture[:data].map { |point| point[:y] }).to eq([ 3, 3 ])
      expect(picture[:data].map { |point| point[:film] }).to eq([ "Nomadland", "CODA" ])
      expect(leader[:data].map { |point| point[:y] }).to eq([ 3, 6 ])
      expect(leader[:data].map { |point| point[:film] }).to eq([ "Nomadland", "Dune" ])
    end
  end

  it "disambiguates ceremonies that share a year" do
    charts = described_class.new(
      nights: [
        {
          year: 2026,
          season_name: "Chaotic 98th Academy Awards (2026)",
          leader: { movie: "Hamnet", wins: 3 },
          picture: { movie: "Hamnet", wins: 3 }
        },
        {
          year: 2026,
          season_name: "98th Academy Awards (2026) kk",
          leader: { movie: "One Battle After Another", wins: 6 },
          picture: { movie: "One Battle After Another", wins: 6 }
        }
      ],
      films: []
    )

    expect(charts.hog[:xAxis][:categories]).to eq([ "2026 · Chaotic 98th", "2026 · 98th kk" ])
    expect(charts.picture[:xAxis][:categories]).to eq([ "2026 · Chaotic 98th", "2026 · 98th kk" ])
  end
end
