require "net/http"
require "json"
require "openssl"

module Admin
  class TmdbSearchController < BaseController
    def search
      query = params[:query].to_s.strip

      if query.blank?
        render json: { error: "Query is required" }, status: :unprocessable_entity and return
      end

      token = Rails.application.credentials.tmdb_access_token
      unless token.present?
        render json: { error: "TMDB credentials not configured" }, status: :unprocessable_entity and return
      end

      uri     = URI("https://api.themoviedb.org/3/search/movie?query=#{URI.encode_www_form_component(query)}&language=en-US&page=1")
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "Bearer #{token}"
      request["Accept"]        = "application/json"

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true, verify_mode: OpenSSL::SSL::VERIFY_NONE) { |h| h.request(request) }

      unless response.is_a?(Net::HTTPSuccess)
        render json: { error: "TMDB request failed (HTTP #{response.code})" }, status: :bad_gateway and return
      end

      results = JSON.parse(response.body)["results"] || []

      render json: results.first(5).map { |m|
        {
          title:      m["title"],
          year:       m["release_date"]&.slice(0, 4),
          poster_url: m["poster_path"] ? "https://image.tmdb.org/t/p/w500#{m['poster_path']}" : nil,
          overview:   m["overview"]&.slice(0, 120)&.then { |s| s.length == 120 ? "#{s}…" : s }
        }
      }
    rescue => e
      render json: { error: e.message }, status: :internal_server_error
    end
  end
end
