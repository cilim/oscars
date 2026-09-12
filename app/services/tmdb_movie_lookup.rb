require "net/http"
require "json"
require "openssl"

class TmdbMovieLookup
  USER_AGENT = "OscarsPool/1.0 (https://github.com/cilim/oscars; season-import scraper)".freeze
  POSTER_BASE = "https://image.tmdb.org/t/p/w500".freeze
  IMDB_BASE = "https://www.imdb.com/title/".freeze

  def initialize(access_token: Rails.application.credentials.tmdb_access_token)
    @access_token = access_token
  end

  def fetch(movie_name, year: nil)
    search = search_movie(movie_name, year: year)
    return nil unless search

    details = movie_details(search["id"]) if search["id"]
    metadata_from(search, details)
  rescue => e
    Rails.logger.warn "TMDB lookup failed for '#{movie_name}': #{e.message}"
    nil
  end

  def fetch_by_id(tmdb_id)
    details = movie_details(tmdb_id)
    return nil unless details

    metadata_from(details, details)
  rescue => e
    Rails.logger.warn "TMDB lookup failed for id '#{tmdb_id}': #{e.message}"
    nil
  end

  def ranked(results, movie_name, year: nil)
    query = normalize_title(movie_name)
    Array(results).each_with_index.sort_by { |result, index|
      [ -result_score(result, query, year), index ]
    }.map(&:first)
  end

  private

  attr_reader :access_token

  def search_movie(movie_name, year: nil)
    uri = URI("https://api.themoviedb.org/3/search/movie?query=#{URI.encode_www_form_component(movie_name)}&language=en-US&page=1")
    response = tmdb_get(uri)
    return nil unless response

    pick_result(JSON.parse(response.body)["results"] || [], movie_name, year)
  end

  def pick_result(results, movie_name, year)
    ranked(results, movie_name, year: year).first
  end

  def result_score(result, query, year)
    title = normalize_title(result["title"])
    original = normalize_title(result["original_title"])
    release_year = result["release_date"].to_s[/\A(\d{4})/, 1]&.to_i
    score = 0

    score += 100 if title == query || original == query
    score += 20 if query.present? && (title.include?(query) || original.include?(query))

    if year && release_year
      delta = release_year - year
      score += case delta
      when -1 then 80
      when 0 then 70
      when -2 then 40
      else
        (delta < -2 || delta > 0) ? -100 : 0
      end
    end

    score
  end

  def normalize_title(name)
    name.to_s.downcase.gsub(/[[:punct:]]+/, " ").squish
  end

  def movie_details(tmdb_id)
    uri = URI("https://api.themoviedb.org/3/movie/#{tmdb_id}?language=en-US")
    response = tmdb_get(uri)
    return nil unless response

    JSON.parse(response.body)
  end

  def metadata_from(search, details)
    poster_path = search["poster_path"].presence || details&.dig("poster_path")
    overview = details&.dig("overview").presence || search["overview"].presence
    imdb_id = details&.dig("imdb_id").presence

    result = {
      "poster_url"  => poster_path ? "#{POSTER_BASE}#{poster_path}" : nil,
      "description" => overview,
      "imdb_url"    => imdb_id ? "#{IMDB_BASE}#{imdb_id}/" : nil
    }

    result.values.any?(&:present?) ? result : nil
  end

  def tmdb_get(uri)
    request = Net::HTTP::Get.new(uri)
    request["Authorization"] = "Bearer #{access_token}"
    request["Accept"] = "application/json"
    request["User-Agent"] = USER_AGENT

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) { |http| http.request(request) }
    response.is_a?(Net::HTTPSuccess) ? response : nil
  end
end
