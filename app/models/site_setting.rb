class SiteSetting < ApplicationRecord
  SITE_DISABLED_KEY = "site_disabled".freeze

  validates :key, presence: true, uniqueness: true

  class << self
    def site_disabled?
      ActiveModel::Type::Boolean.new.cast(find_by(key: SITE_DISABLED_KEY)&.value)
    end

    def site_disabled=(disabled)
      setting = find_or_initialize_by(key: SITE_DISABLED_KEY)
      setting.value = ActiveModel::Type::Boolean.new.cast(disabled).to_s
      setting.save!
    end
  end
end
