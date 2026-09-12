class OscarHistoryCharts
  GOLD = "#D5BA6D"
  GOLD_DARK = "#B69F66"
  RED = "#801B1D"
  TEXT = "#1A1A1A"
  MUTED = "#55565A"
  GRID = "#E5E3DD"
  HEARTBREAK_MIN_NOMS = 5

  def initialize(nights:, films:)
    @nights = nights
    @films = films
  end

  def hog
    hog_nights = @nights.select { |night| night[:leader].present? }
    points = hog_nights.map do |night|
      leader = night[:leader]
      {
        y: leader[:wins],
        film: leader[:movie],
        year: night[:year],
        name: category_label(night)
      }
    end

    base_chart.merge(
      chart: { type: "column", backgroundColor: "transparent", height: 360 },
      xAxis: category_axis(points.map { |point| point[:name] }, "Ceremony"),
      yAxis: value_axis("Oscars won by the night's top film"),
      tooltip: {
        headerFormat: "",
        pointFormat: "<b>{point.name}</b><br/>{point.film} took <b>{point.y}</b> Oscars"
      },
      series: [ {
        name: "Wins by the night's top film",
        data: points,
        color: GOLD
      } ]
    )
  end

  def heartbreak
    notable = @films.select { |film| film[:nominations] >= HEARTBREAK_MIN_NOMS }
    closers = notable.select { |film| film[:wins].positive? }
    snubs = notable.select { |film| film[:wins].zero? }

    base_chart.merge(
      chart: { type: "scatter", backgroundColor: "transparent", height: 400, zooming: { type: "xy" } },
      xAxis: value_axis("Nominations", min: 0),
      yAxis: value_axis("Wins", min: 0),
      tooltip: {
        headerFormat: "",
        pointFormat: "<b>{point.name}</b><br/>{point.x} nominations → {point.y} wins"
      },
      series: [
        {
          name: "Won something",
          color: GOLD_DARK,
          data: scatter_points(closers)
        },
        {
          name: "Nominated into oblivion",
          color: RED,
          data: scatter_points(snubs)
        }
      ]
    )
  end

  def picture
    labels = @nights.map { |night| category_label(night) }

    base_chart.merge(
      chart: { type: "column", backgroundColor: "transparent", height: 360 },
      xAxis: category_axis(labels, "Ceremony"),
      yAxis: value_axis("Oscars"),
      tooltip: {
        shared: true,
        headerFormat: "<span style=\"font-size:12px\"><b>{point.key}</b></span><br/>",
        pointFormat: "{series.name}: <b>{point.film}</b> — {point.y}<br/>"
      },
      series: [
        {
          name: "Best Picture winner",
          color: GOLD,
          data: named_column_points(:picture)
        },
        {
          name: "Night's biggest winner",
          color: RED,
          data: named_column_points(:leader)
        }
      ]
    )
  end

  private

  def named_column_points(role)
    @nights.map do |night|
      entry = night[role]
      {
        y: entry ? entry[:wins].to_i : 0,
        film: entry&.dig(:movie).presence || "—",
        year: night[:year]
      }
    end
  end

  def category_label(night)
    year = night[:year].to_s
    return year unless @nights.count { |other| other[:year] == night[:year] } > 1

    extra = night[:season_name].to_s
      .gsub(/\s*\(\d{4}\)/, "")
      .gsub(/\b(Academy Awards|Oscars)\b/i, "")
      .squish
      .truncate(22, omission: "…")
    extra.present? ? "#{year} · #{extra}" : year
  end

  def scatter_points(films)
    films.map do |film|
      {
        x: film[:nominations],
        y: film[:wins],
        name: "#{film[:movie]} (#{film[:year]})"
      }
    end
  end

  def base_chart
    {
      title: { text: nil },
      credits: { enabled: true },
      legend: {
        itemStyle: { color: TEXT, fontFamily: "Inter, sans-serif" }
      },
      plotOptions: {
        column: {
          borderRadius: 4,
          borderWidth: 0,
          maxPointWidth: 48
        },
        scatter: {
          marker: { radius: 7, symbol: "circle" }
        }
      }
    }
  end

  def category_axis(categories, title)
    {
      categories: categories,
      title: { text: title, style: { color: MUTED } },
      labels: { style: { color: MUTED } },
      lineColor: GRID,
      tickColor: GRID
    }
  end

  def value_axis(title, min: 0)
    {
      min: min,
      title: { text: title, style: { color: MUTED } },
      labels: { style: { color: MUTED } },
      gridLineColor: GRID,
      allowDecimals: false
    }
  end
end
