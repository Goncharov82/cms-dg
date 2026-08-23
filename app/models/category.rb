class Category < ApplicationRecord
  include Sluggable
  include AccessControlled

  belongs_to :parent, class_name: "Category", optional: true, inverse_of: :children
  has_many :children, class_name: "Category", foreign_key: :parent_id, dependent: :restrict_with_error, inverse_of: :parent
  has_many :articles, dependent: :restrict_with_error
  has_one_attached :image

  enum :status, { draft: 0, published: 1 }, default: :draft, validate: true

  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :articles_per_page, inclusion: { in: [ 6, 9, 12, 18, 24 ] }

  def full_path
    nodes = []
    current = self
    visited_ids = []

    while current && !visited_ids.include?(current.id)
      nodes.unshift(current.slug)
      visited_ids << current.id
      current = current.parent
    end

    nodes.compact_blank.join("/")
  end

  def full_name
    names = []
    current = self
    visited_ids = []

    while current && !visited_ids.include?(current.id)
      names.unshift(current.name)
      visited_ids << current.id
      current = current.parent
    end

    names.compact_blank.join(" / ")
  end

  def public_path = "/#{slug}"

  def rendered_name = ::ContentVariables.render(name)
  def rendered_short_description = ::ContentVariables.render(short_description)
  def rendered_description = ::ContentVariables.render(description)
  def rendered_seo_title = ::ContentVariables.render(seo_title)
  def rendered_meta_description = ::ContentVariables.render(meta_description.presence || short_description)

  private

  def slug_source
    name
  end
end
