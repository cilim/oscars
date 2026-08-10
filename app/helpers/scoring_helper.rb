module ScoringHelper
  def format_points(value)
    return "0" if value.zero?

    value.positive? ? "+#{value}" : value.to_s
  end

  def pick_type_legend_label(pick_type)
    parts = [ "#{pick_type.emoji} #{pick_type.name} (#{format_points(pick_type.points_on_correct)} / #{format_points(pick_type.points_on_incorrect)})" ]
    if pick_type.allow_multiple_selections?
      parts << "up to #{pick_type.max_selections} picks"
    end
    parts.join(", ")
  end

  def pick_chip_label(pick_type, points)
    return pick_type.emoji if points.nil?

    "#{pick_type.emoji} #{format_points(points)}"
  end

  def points_color_class(points)
    if points.positive?
      "text-emerald-700"
    elsif points.negative?
      "text-red-600"
    else
      "text-gray-400"
    end
  end
end
