class MenuItem < ApplicationRecord
  include Sluggable

  enum :item_type, { page: 0, category: 1, article: 2, external: 3 }, default: :page, validate: true
  enum :status, { draft: 0, published: 1 }, default: :draft, validate: true

  validates :label, :slug, presence: true
  validates :slug, uniqueness: true
  validates :url, presence: true, if: :external?

  def slug_source = label
end
