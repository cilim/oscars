class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :players, dependent: :destroy
  has_many :seasons, through: :players

  validates :display_name, presence: true
  validates :email_address, presence: true, uniqueness: true

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  scope :admins, -> { where(admin: true) }

  def admin?
    admin
  end
end
