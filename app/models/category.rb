class Category < ApplicationRecord
  include Sluggable

  belongs_to :parent, class_name: "Category", optional: true, inverse_of: :children
  has_many :children, class_name: "Category", foreign_key: :parent_id, dependent: :restrict_with_error, inverse_of: :parent
  has_many :articles, dependent: :restrict_with_error
  has_one_attached :image

  enum :status, { draft: 0, published: 1 }, default: :draft, validate: true

  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :articles_per_page, inclusion: { in: [6, 9, 12, 18, 24] }

  private

  def slug_source
    name
  end
end
