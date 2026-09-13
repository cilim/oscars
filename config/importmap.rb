# Pin npm packages by running ./bin/importmap

pin "application"
pin "chart_point_navigation"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "emoji-picker-element", to: "https://cdn.jsdelivr.net/npm/emoji-picker-element@1.22.8/index.js"
pin "highcharts", to: "https://cdn.jsdelivr.net/npm/highcharts@12.4.0/+esm"
pin "@rails/actioncable", to: "actioncable.esm.js"
