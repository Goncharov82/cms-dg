module AccessControlled
  extend ActiveSupport::Concern

  included do
    validates :visibility, inclusion: { in: %w[public admin] }
    scope :publicly_accessible, -> { where(visibility: "public") }
    scope :accessible_to, ->(user) { user&.admin? ? all : publicly_accessible }
  end

  def admin_only? = visibility == "admin"
end
