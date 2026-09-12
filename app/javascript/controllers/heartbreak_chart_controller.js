import { Controller } from "@hotwired/stimulus"
import HighchartsModule from "highcharts"

const Highcharts = [ HighchartsModule, HighchartsModule?.highcharts, HighchartsModule?.default ]
  .find((candidate) => candidate && typeof candidate.chart === "function")

Highcharts.setOptions({
  chart: {
    style: { fontFamily: "Inter, system-ui, sans-serif" }
  },
  tooltip: {
    backgroundColor: "#FFFFFF",
    borderColor: "#E5E3DD",
    borderRadius: 8,
    style: { color: "#1A1A1A", fontFamily: "Inter, system-ui, sans-serif" }
  }
})

export default class extends Controller {
  static targets = [ "container", "select" ]
  static values = { panels: Object }

  connect() {
    this.renderChart()
  }

  disconnect() {
    this.destroyChart()
  }

  change() {
    this.renderChart()
  }

  renderChart() {
    this.destroyChart()
    const options = this.panelsValue[this.selectTarget.value]
    if (!options) return

    this.chart = Highcharts.chart(this.containerTarget, options)
  }

  destroyChart() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }
}
