class Page < ApplicationRecord
  include Sluggable
  include AccessControlled

  enum :status, { draft: 0, published: 1 }, default: :draft, validate: true

  normalizes :title, with: ->(title) { title.strip }

  validates :title, :body_html, presence: true

  def rendered_title = ::ContentVariables.render(title)
  def rendered_body_html = ::ContentVariables.render(body_html)
  def rendered_seo_title = ::ContentVariables.render(seo_title)
  def rendered_meta_description = ::ContentVariables.render(meta_description)

  private

  def normalize_slug
    return self.slug = "/" if slug == "/"

    super
  end

  def slug_source
    title
  end
end
