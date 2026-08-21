class LegacyRedirect < ApplicationRecord
  validates :old_path, :new_path, presence: true
  validates :old_path, uniqueness: true
  validates :http_status, inclusion: { in: [ 301, 308 ] }

  before_validation do
    self.old_path = "/#{old_path.to_s.sub(%r{\A/+}, '')}"
    self.new_path = "/#{new_path.to_s.sub(%r{\A/+}, '')}"
  end
end
