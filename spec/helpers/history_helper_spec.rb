RSpec.describe HistoryHelper do
  describe "#heartbreak_panels_json" do
    it "indexes panel charts by label for the Stimulus controller" do
      panels = [
        { label: "All", chart: { series: [] } },
        { label: "2020s", chart: { series: [ { data: [ 1 ] } ] } }
      ]

      expect(helper.heartbreak_panels_json(panels)).to eq(
        "All" => { series: [] },
        "2020s" => { series: [ { data: [ 1 ] } ] }
      )
    end
  end
end
