class MediaAsset < ApplicationRecord
  has_one_attached :file

  validates :source_path, uniqueness: { scope: :legacy_source }, allow_nil: true
  validates :file, presence: true

  def public_path
    "/images/blog/#{ERB::Util.url_encode(public_filename)}"
  end

  def public_filename
    asset = canonical_asset
    original = asset.file.filename.to_s
    extension = File.extname(original).downcase
    basename = File.basename(original, File.extname(original)).parameterize.presence || "image"
    fingerprint = asset.sha256.presence&.first(16) || "asset-#{asset.id}"
    "#{basename}-#{fingerprint}#{extension}"
  end

  def canonical_asset
    return self if sha256.blank?

    self.class.where(sha256: sha256).order(:id).first || self
  end

  class << self
    def find_by_public_filename!(filename)
      fingerprint = filename.to_s.match(/-([0-9a-f]{16})\.[^.]+\z/i)&.captures&.first
      if fingerprint.blank?
        asset_id = filename.to_s.match(/-asset-(\d+)\.[^.]+\z/i)&.captures&.first
        asset = find_by(id: asset_id)
        raise ActiveRecord::RecordNotFound unless asset&.public_filename == filename

        return asset
      end

      asset = where("sha256 LIKE ?", "#{fingerprint}%").order(:id).first
      raise ActiveRecord::RecordNotFound unless asset&.public_filename == filename

      asset
    end

    def rewrite_legacy_paths(html)
      html.to_s.gsub(%r{(["'])/{1,2}media/(\d+)/[^"']+\1}) do |match|
        quote = Regexp.last_match(1)
        asset_id = Regexp.last_match(2)
        asset = find_by(id: asset_id)
        asset ? "#{quote}#{asset.public_path}#{quote}" : match
      end
    end
  end
end
