namespace :oscars do
  desc "Scrape one ceremony from Wikipedia and import into the database. Usage: rails oscars:scrape[2022]"
  task :scrape, [ :year ] => :environment do |_t, args|
    year = (args[:year] || raise("Usage: rails oscars:scrape[YEAR]")).to_i

    scraper = OscarsScraper.new(year, persist_wikitext: false)
    data = scraper.call

    if data.nil?
      abort "Scrape failed for #{year}:\n  - #{scraper.errors.join("\n  - ")}"
    end

    importer = SeasonImporter.new(data)
    season = importer.call

    if season
      puts "Imported #{season.name} (id: #{season.id}) — #{data['categories'].length} categories."
    else
      abort "Import failed: #{importer.errors.join(', ')}"
    end
  end

  desc "Canary: fetch a ceremony from Wikipedia and assert scrape invariants. Usage: rails oscars:canary[2026]"
  task :canary, [ :year ] => :environment do |_t, args|
    year = (args[:year] || (Time.current.month >= 3 ? Time.current.year : Time.current.year - 1)).to_i
    puts "Running Wikipedia scrape canary for #{year}..."

    scraper = OscarsScraper.new(year, persist_wikitext: false)
    data = scraper.call

    if data.nil?
      abort "Canary FAILED for #{year}:\n  - #{scraper.errors.join("\n  - ")}"
    end

    cats = data["categories"]
    noms = cats.sum { |c| c["nominees"].length }
    puts "Canary OK — #{cats.length} categories, #{noms} nominees (source: #{scraper.parse_source})"
    cats.each do |cat|
      puts "  #{cat['name']}: #{cat['nominees'].length}"
    end
  end
end
