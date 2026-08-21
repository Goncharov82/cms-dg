class Author < ApplicationRecord
  has_one_attached :avatar
  has_many :articles, dependent: :nullify

  validates :name, presence: true
  validates :legacy_id, uniqueness: { scope: :legacy_source }, allow_nil: true
end
