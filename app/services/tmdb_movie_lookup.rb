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

  def fetch(movie_name)
    search = search_movie(movie_name)
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

  private

  attr_reader :access_token

  def search_movie(movie_name)
    uri = URI("https://api.themoviedb.org/3/search/movie?query=#{URI.encode_www_form_component(movie_name)}&language=en-US&page=1")
    response = tmdb_get(uri)
    return nil unless response

    (JSON.parse(response.body)["results"] || []).first
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
