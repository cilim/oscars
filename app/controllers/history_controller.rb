class HistoryController < ApplicationController
  def show
    payload = OscarHistory.new.call
    @nights = payload[:nights]
    @films = payload[:films]
    charts = OscarHistoryCharts.new(nights: @nights, films: @films)
    @hog_chart = charts.hog
    @heartbreak_decades = charts.heartbreak_by_decade
    @picture_chart = charts.picture
  end
end
