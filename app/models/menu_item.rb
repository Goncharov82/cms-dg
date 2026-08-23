class MenuItem < ApplicationRecord
  include Sluggable
  include AccessControlled

  enum :item_type, { page: 0, category: 1, article: 2, external: 3 }, default: :page, validate: true
  enum :status, { draft: 0, published: 1 }, default: :draft, validate: true

  belongs_to :target_category, class_name: "Category", foreign_key: :target_id, optional: true

  validates :label, :slug, presence: true
  validates :slug, uniqueness: true
  validates :url, presence: true, if: :external?
  validates :target_category, presence: true, if: :category?

  before_validation :sync_category_target, if: :category?

  def slug_source = label
  def rendered_label = ::ContentVariables.render(label)
  def rendered_description = ::ContentVariables.render(description)

  private

  def sync_category_target
    self.target_label = target_category&.full_name
  end
end
