function visit(path) {
  if (window.Turbo?.visit) {
    window.Turbo.visit(path)
  } else {
    window.location.assign(path)
  }
}

function pointClickHandler() {
  const path = this.options?.seasonPath
  if (!path) return

  visit(path)
}

function dataHasSeasonPaths(options) {
  return (options.series || []).some((series) =>
    (series.data || []).some(
      (point) => point && typeof point === "object" && point.seasonPath
    )
  )
}

export function withChartPointNavigation(options) {
  if (!options || !dataHasSeasonPaths(options)) return options

  const chartType = options.chart?.type
  const plotOptions = { ...(options.plotOptions || {}) }

  if (chartType === "scatter") {
    plotOptions.scatter = {
      ...(plotOptions.scatter || {}),
      cursor: "pointer",
      point: {
        ...(plotOptions.scatter?.point || {}),
        events: {
          ...(plotOptions.scatter?.point?.events || {}),
          click: pointClickHandler
        }
      }
    }
  }

  if (chartType === "column") {
    plotOptions.column = {
      ...(plotOptions.column || {}),
      cursor: "pointer",
      point: {
        ...(plotOptions.column?.point || {}),
        events: {
          ...(plotOptions.column?.point?.events || {}),
          click: pointClickHandler
        }
      }
    }
  }

  return { ...options, plotOptions }
}
