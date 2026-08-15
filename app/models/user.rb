class User < ApplicationRecord
  has_secure_password

  enum :role, { editor: 0, admin: 1 }, default: :editor, validate: true

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 12 }, if: -> { password.present? }
end
