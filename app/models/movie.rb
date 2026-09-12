class Movie < ApplicationRecord
  belongs_to :season
  has_many :nominees, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :season_id }

  before_validation :normalize_name

  COUNTRY_NAMES = YAML.load_file(Rails.root.join("config/oscar_country_names.yml"))
                      .to_set { |name| name.to_s.strip.downcase }
                      .freeze

  def self.normalized_name(raw)
    name = raw.to_s.strip
    return name if name.blank?

    match = name.match(/\A(.*)\s+\(([^)]+)\)\z/)
    return name unless match

    title = match[1].strip
    suffix = match[2].strip
    country_suffix?(suffix) ? title : name
  end

  def self.country_suffix?(text)
    candidate = text.to_s.strip.downcase
    return false if candidate.blank?

    COUNTRY_NAMES.include?(candidate) || COUNTRY_NAMES.include?(candidate.delete_prefix("the ").strip)
  end
  private_class_method :country_suffix?

  def self.find_or_initialize_for_season(season, raw_name)
    season.movies.find_or_initialize_by(name: normalized_name(raw_name))
  end

  def self.merge_duplicate!(duplicate, canonical)
    return canonical if duplicate.id == canonical.id

    %i[poster_url description imdb_url].each do |attr|
      canonical[attr] = duplicate[attr] if canonical[attr].blank? && duplicate[attr].present?
    end
    duplicate.nominees.update_all(movie_id: canonical.id)
    duplicate.reload.destroy!
    canonical.save! if canonical.changed?
    canonical
  end

  def modal_available?
    poster_url.present? || description.present? || imdb_url.present?
  end

  private

  def normalize_name
    self.name = self.class.normalized_name(name) if name.present?
  end
end
