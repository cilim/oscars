module HistoryHelper
  def hog_kicker(nights)
    return if nights.blank?

    hogs = nights.select { |night| night.dig(:leader, :wins).to_i >= 7 }
    if hogs.size >= 2
      names = hogs.map { |night| "#{night[:leader][:movie]} (#{night_caption(nights, night)})" }.to_sentence
      "#{names} each took #{hogs.first[:leader][:wins]}. That's not a win, that's a raid."
    else
      peak = nights.max_by { |night| night.dig(:leader, :wins).to_i }
      spread = nights.min_by { |night| night.dig(:leader, :wins).to_i }
      lead = "#{night_caption(nights, peak)}: #{peak[:leader][:movie]} led with #{peak[:leader][:wins]}."
      return lead if nights.size == 1 || peak.dig(:leader, :wins) == spread.dig(:leader, :wins)

      "#{lead} #{night_caption(nights, spread)} passed the statue around — #{spread[:leader][:movie]} topped out at #{spread[:leader][:wins]}."
    end
  end

  def heartbreak_kicker(films)
    notable = films.select { |film| film[:nominations] >= OscarHistoryCharts::HEARTBREAK_MIN_NOMS }
    return if notable.blank?

    snub = notable.select { |film| film[:wins].zero? }.max_by { |film| film[:nominations] }
    closer = notable.max_by { |film| film[:wins].to_f / film[:nominations] }

    bits = []
    if closer && closer[:wins].positive?
      rate = ((closer[:wins].to_f / closer[:nominations]) * 100).round
      bits << "#{closer[:movie]} closed #{closer[:wins]} of #{closer[:nominations]} (#{rate}%)."
    end
    if snub
      bits << "#{snub[:movie]} (#{snub[:year]}) went #{snub[:nominations]}-for-0. Iconic, in the worst way."
    end
    bits.join(" ")
  end

  def picture_kicker(nights)
    splits = nights.select { |night| night[:split] }
    if splits.empty?
      "Every Best Picture winner in this window also led the night. Peaceful. Suspicious."
    else
      splits.map { |night|
        "#{night_caption(nights, night)}: #{night[:picture][:movie]} won Picture with #{night[:picture][:wins]}, " \
          "while #{night[:leader][:movie]} hauled #{night[:leader][:wins]}."
      }.join(" ")
    end
  end

  private

    def night_caption(nights, night)
      if nights.count { |other| other[:year] == night[:year] } > 1
        night[:season_name].presence || night[:year].to_s
      else
        night[:year].to_s
      end
    end
end
