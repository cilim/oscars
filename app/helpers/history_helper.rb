module HistoryHelper
  def heartbreak_panels_json(panels)
    panels.index_by { |panel| panel[:label] }.transform_values { |panel| panel[:chart] }
  end
end
