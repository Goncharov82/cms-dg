class Page < ApplicationRecord
  include Sluggable

  enum :status, { draft: 0, published: 1 }, default: :draft, validate: true

  normalizes :title, with: ->(title) { title.strip }

  validates :title, :body_html, presence: true
  validates :visibility, inclusion: { in: %w[public private] }

  private

  def normalize_slug
    return self.slug = "/" if slug == "/"

    super
  end

  def slug_source
    title
  end
end
