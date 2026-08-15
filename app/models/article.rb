class Article < ApplicationRecord
  include Sluggable

  belongs_to :category, optional: true

  enum :status, { draft: 0, published: 1 }, default: :draft, validate: true

  normalizes :title, with: ->(title) { title.strip }

  validates :title, :body, presence: true

  before_validation :set_published_at, if: :published?

  scope :recent_first, -> { order(created_at: :desc) }

  private

  def set_published_at
    self.published_at ||= Time.current
  end

  def slug_source
    title
  end
end
