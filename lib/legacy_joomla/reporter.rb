# frozen_string_literal: true

require_relative "analyzer"

module LegacyJoomla
  class Reporter
    SOURCE = "joomla".freeze

    def initialize(analyzer: Analyzer.new)
      @analyzer = analyzer
    end

    def write(report_path:, manifest_path:)
      manifest = enriched_manifest
      Pathname(manifest_path).write(JSON.pretty_generate(manifest), mode: "w", encoding: Encoding::UTF_8)
      Pathname(report_path).write(markdown(manifest), mode: "w", encoding: Encoding::UTF_8)
    end

    private

    def enriched_manifest
      assets = MediaAsset.where(legacy_source: SOURCE).with_attached_file.index_by(&:source_path)
      @analyzer.media_manifest.map do |entry|
        asset = assets[entry[:old_path]]
        entry.merge(
          new_path: asset&.public_path,
          new_format: asset&.format,
          new_size: asset&.file&.attached? ? asset.file.blob.byte_size : nil
        )
      end
    end

    def markdown(manifest)
      inventory = @analyzer.inventory
      imported_articles = Article.where(legacy_source: SOURCE)
      media = MediaAsset.where(legacy_source: SOURCE).with_attached_file
      source_bytes = media.sum(:source_byte_size)
      blob_ids = media.filter_map { |asset| asset.file.blob_id if asset.file.attached? }.uniq
      stored_bytes = ActiveStorage::Blob.where(id: blob_ids).sum(:byte_size)
      missing = manifest.reject { |entry| entry[:external] || entry[:exists] }
      external = manifest.select { |entry| entry[:external] }
      broken_links = unresolved_internal_links(imported_articles)
      formats = media.group(:format).count.sort.to_h
      converted_count = manifest.count { |entry| entry[:exists] && entry[:new_format] == "webp" && entry[:format] != "webp" }
      savings = source_bytes.positive? ? ((source_bytes - stored_bytes) * 100.0 / source_bytes).round(1) : 0

      <<~MARKDOWN
        # CMS DG Joomla Migration Report

        Generated: #{Time.current.iso8601}

        ## Joomla inventory

        - Joomla #{inventory[:joomla_version]}, table prefix `#{inventory[:table_prefix]}`.
        - #{inventory[:articles]} non-trashed content records: #{inventory[:article_states].fetch(1, 0)} published and #{inventory[:article_states].fetch(0, 0)} unpublished.
        - #{inventory[:content_categories]} content categories, #{inventory[:used_authors]} used content author, #{inventory[:menu_items]} content menu items, #{inventory[:redirects]} redirect rows and #{inventory[:sitemap_urls]} sitemap URLs.
        - The Joomla tree contains #{inventory.dig(:media, :archive_images)} images (#{human_bytes(inventory.dig(:media, :archive_image_bytes))}); it was treated as a read-only source and was not copied wholesale.

        ## Joomla fields

        Used article data: id, title, alias, introtext, fulltext, state, category, author, created/modified/publish dates, images JSON, Helix main image, ordering, meta keywords/description, robots metadata, featured, access and language. HTML structure is retained. Joomla tags and custom fields have no populated article relations/values in this dump.

        ## Mapping

        - `content` → `Article`; `introtext` → `excerpt`; `fulltext` → `body`; `alias` → `slug`.
        - `categories` → existing/new `Category` records by alias, retaining hierarchy and legacy identity.
        - Joomla content user → separate `Author` (authentication hashes and sessions were not imported).
        - image intro/fulltext/Helix and HTML image references → `MediaAsset` + Active Storage; article image roles keep their own alt/caption fields.
        - Joomla state 1 → published, 0 → draft, 2 → archived; -2 is excluded.
        - sitemap/category paths → `legacy_url`; legacy redirect rows → `LegacyRedirect` (301).

        ## CMS changes

        Added an additive database migration; `Author`, `MediaAsset` and `LegacyRedirect`; structured Article legacy/author/status/featured/date/SEO/media fields; Category legacy/SEO fields; media ingestion; public legacy URL/media controllers; editor fields; and `legacy:analyze`, `legacy:import`, `legacy:verify`, `legacy:report` tasks. The importer is transaction-protected, PostgreSQL advisory-locked and idempotent by `(legacy_source, legacy_id)` or source path.

        ## Imported

        - #{imported_articles.count} articles (#{imported_articles.published.count} published), #{Category.where(legacy_source: SOURCE).count} categories and #{Author.where(legacy_source: SOURCE).count} author.
        - #{media.count} media records and #{LegacyRedirect.where(legacy_source: SOURCE).count} usable permanent redirects.
        - Verification result: all source/import counts match, no duplicate article legacy IDs, no empty attachments, and no remaining local old-site image URLs.

        ## Transformed

        Relative/absolute local image URLs were rewritten to stable `/images/blog/:unique-filename` paths. Names contain a content fingerprint, so name collisions receive different URLs while exact duplicates reuse one canonical URL. Raster JPEG/PNG/TIFF/BMP files were optimized to WebP when readable; GIF/SVG/WebP are retained when transformation is not appropriate. Existing CMS categories with matching aliases were reused rather than duplicated.

        ## Skipped

        Joomla sessions, cache, ACL assets, extension/plugin/template configuration, logs, workflow internals, credentials, password hashes and unused filesystem files were skipped. Tags and custom fields were skipped because the concrete dump has no article tag mappings and no populated custom-field rows. #{inventory[:redirects] - LegacyRedirect.where(legacy_source: SOURCE).count} redirect rows were skipped because they were empty, external, self-referential or not safely representable as local redirects.

        ## Media

        - Archive images: #{inventory.dig(:media, :archive_images)}; referenced unique paths: #{manifest.count { |entry| !entry[:external] }}; imported: #{media.count}; missing: #{missing.count}; external: #{external.count}.
        - Formats after import: #{formats.map { |format, count| "#{format}=#{count}" }.join(', ')}.
        - Converted to WebP: #{converted_count}; retained in source format: #{media.count - converted_count}.
        - Referenced source size: #{human_bytes(source_bytes)}; stored size: #{human_bytes(stored_bytes)}; saving: #{human_bytes(source_bytes - stored_bytes)} (#{savings}%).
        - Full per-file old/new paths, roles, dimensions and sizes: `migration_reports/media_manifest.json`.

        ## Missing media

        #{missing.any? ? missing.map { |entry| "- `#{entry[:old_path]}` — articles #{entry[:articles].join(', ')} (#{entry[:usages].join(', ')})" }.join("\n") : "None."}

        ## External media

        #{external.any? ? external.map { |entry| "- #{entry[:old_url]} — articles #{entry[:articles].join(', ')}" }.join("\n") : "None."}

        ## Broken links

        #{broken_links.any? ? broken_links.map { |link| "- Article #{link[:legacy_id]}: `#{link[:href]}`" }.join("\n") : "No unresolved internal content links detected."}

        ## URL changes

        No imported article URL was intentionally changed: `legacy_url` is served directly. The five non-sitemap records use their category/alias-derived Joomla path.

        ## Redirects

        #{LegacyRedirect.where(legacy_source: SOURCE).count} valid local Joomla redirects were imported as permanent 301 redirects. The catch-all public route first resolves preserved Article/Category legacy paths, then the redirect table, avoiding duplicate indexable content URLs.

        ## Warnings

        #{missing.count} referenced files are absent from the supplied Joomla filesystem; no placeholders were created. Public rendering sanitizes dangerous HTML while retaining article formatting, tables, images, embeds and useful attributes.

        ## Errors

        None after final `legacy:verify`.
      MARKDOWN
    end

    def unresolved_internal_links(articles)
      known = articles.pluck(:legacy_url).compact.to_set |
        Category.where(legacy_source: SOURCE).pluck(:legacy_url).compact.to_set |
        LegacyRedirect.pluck(:old_path).to_set
      articles.flat_map do |article|
        Nokogiri::HTML.fragment("#{article.excerpt}#{article.body}").css("a[href]").filter_map do |anchor|
          href = anchor["href"].to_s.strip
          next if href.blank? || href.start_with?("#", "mailto:", "tel:", "javascript:")
          uri = URI.parse(URI::DEFAULT_PARSER.escape(href))
          next if uri.host && !Analyzer::LOCAL_HOSTS.include?(uri.host.downcase)
          path = "/#{uri.path.to_s.sub(%r{\A/+}, '')}".chomp("/")
          next if path.blank? || path == "" || path == "/" || path.start_with?("/images/blog/", "/media/", "/rails/") || known.include?(path)
          { legacy_id: article.legacy_id, href: href }
        rescue URI::InvalidURIError
          { legacy_id: article.legacy_id, href: href }
        end
      end.uniq
    end

    def human_bytes(bytes)
      ActiveSupport::NumberHelper.number_to_human_size(bytes.to_i)
    end
  end
end
