# frozen_string_literal: true

require_relative "analyzer"

module LegacyJoomla
  class Verifier
    SOURCE = "joomla".freeze

    def initialize(analyzer: Analyzer.new)
      @analyzer = analyzer
    end

    def call
      imported = Article.where(legacy_source: SOURCE)
      missing_files = MediaAsset.where(legacy_source: SOURCE).select { |asset| !asset.file.attached? || asset.file.blob.byte_size.zero? }
      legacy_image_links = imported.where("body LIKE '%goncharoff.pro/images/%' OR body LIKE '%src=\"images/%'").count
      errors = []
      errors << "article count mismatch" unless imported.count == @analyzer.articles.count
      errors << "published article count mismatch" unless imported.published.count == @analyzer.articles.count { |row| row["state"] == 1 }
      errors << "media attachments missing or empty: #{missing_files.map(&:id).join(', ')}" if missing_files.any?
      errors << "legacy local image links remain: #{legacy_image_links}" if legacy_image_links.positive?
      errors << "legacy identity duplicates" if imported.group(:legacy_id).having("COUNT(*) > 1").exists?

      {
        ok: errors.empty?, errors: errors, articles: imported.count, published_articles: imported.published.count,
        categories: Category.where(legacy_source: SOURCE).count, authors: Author.where(legacy_source: SOURCE).count,
        media: MediaAsset.where(legacy_source: SOURCE).count, redirects: LegacyRedirect.where(legacy_source: SOURCE).count,
        remaining_legacy_image_links: legacy_image_links
      }
    end
  end
end
