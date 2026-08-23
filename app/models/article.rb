class Article < ApplicationRecord
  include Sluggable
  include AccessControlled

  belongs_to :category, optional: true
  belongs_to :author, optional: true
  belongs_to :preview_image, class_name: "MediaAsset", optional: true
  belongs_to :intro_image, class_name: "MediaAsset", optional: true
  belongs_to :fulltext_image, class_name: "MediaAsset", optional: true
  belongs_to :main_image, class_name: "MediaAsset", optional: true

  enum :status, { draft: 0, published: 1, archived: 2 }, default: :draft, validate: true

  normalizes :title, with: ->(title) { title.strip }

  validates :title, presence: true
  validate :content_is_present

  before_validation :set_published_at, if: :published?

  scope :recent_first, -> { order(created_at: :desc) }

  def public_path
    return "/#{category.slug}/#{slug}" if category.present?

    legacy_url.presence || "/#{slug}"
  end

  def rendered_body
    ::ContentVariables.render(MediaAsset.rewrite_legacy_paths(body))
  end

  def rendered_title = ::ContentVariables.render(title)
  def rendered_excerpt = ::ContentVariables.render(MediaAsset.rewrite_legacy_paths(excerpt))
  def rendered_seo_title = ::ContentVariables.render(seo_title)
  def rendered_meta_description = ::ContentVariables.render(meta_description.presence || excerpt)

  private

  def content_is_present
    errors.add(:body, "или краткий анонс должны быть заполнены") if body.blank? && excerpt.blank?
  end

  def set_published_at
    self.published_at ||= Time.current
  end

  def slug_source
    title
  end
end
