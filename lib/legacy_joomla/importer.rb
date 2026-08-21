# frozen_string_literal: true

require "digest"
require "fileutils"
require "image_processing/vips"
require "tempfile"
require_relative "analyzer"

module LegacyJoomla
  class Importer
    SOURCE = "joomla".freeze
    RASTER_TO_WEBP = %w[.jpg .jpeg .png .bmp .tif .tiff].freeze

    attr_reader :analyzer, :stats

    def initialize(analyzer: Analyzer.new)
      @analyzer = analyzer
      @stats = Hash.new(0)
      @media_by_source_path = {}
      @article_urls_by_legacy_id = analyzer.articles.to_h { |row| [ row["id"].to_i, analyzer.article_url(row) ] }
      @article_urls_by_alias = analyzer.articles.group_by { |row| row["alias"].to_s }.filter_map do |alias_name, rows|
        [ alias_name, analyzer.article_url(rows.first) ] if alias_name.present? && rows.one?
      end.to_h
    end

    def call
      ActiveRecord::Base.transaction do
        ActiveRecord::Base.connection.execute("SELECT pg_advisory_xact_lock(hashtext('cms_dg_legacy_joomla_import'))")
        import_authors
        import_categories
        import_media
        import_articles
        import_redirects
      end
      stats
    end

    private

    def import_authors
      used_ids = analyzer.articles.map { |row| row["created_by"] }.uniq
      analyzer.table("users").select { |row| used_ids.include?(row["id"]) }.each do |row|
        author = Author.find_or_initialize_by(legacy_source: SOURCE, legacy_id: row["id"])
        author.assign_attributes(name: row["name"].presence || row["username"], email: row["email"].presence)
        author.save!
        stats[:authors] += 1
      end
    end

    def import_categories
      rows = analyzer.table("categories").select { |row| row["extension"] == "com_content" }
      rows.each { |row| upsert_category(row) }
      rows.each do |row|
        category = category_for(row["id"])
        parent = category_for(row["parent_id"])
        category.update!(parent: parent) if parent && category.parent_id != parent.id
      end
    end

    def upsert_category(row)
      category = Category.find_or_initialize_by(legacy_source: SOURCE, legacy_id: row["id"])
      natural_match = Category.where.not(id: category.id).find_by(slug: row["alias"]) ||
        Category.where.not(id: category.id).find_by(name: row["title"])
      if natural_match && category.persisted?
        Article.where(category: category, legacy_source: SOURCE).update_all(category_id: natural_match.id)
        category.destroy!
        category = natural_match
      elsif natural_match
        category = natural_match
      end
      metadata = parse_json(row["metadata"])
      category.assign_attributes(
        name: row["title"], slug: conflict_free_slug(Category, row["alias"], category), description: row["description"],
        status: row["published"] == 1 ? :published : :draft, visibility: row["access"].to_i <= 1 ? "public" : "admin",
        seo_title: nil, meta_description: row["metadesc"], meta_keywords: row["metakey"], robots: metadata["robots"],
        position: row["lft"].to_i, language: row["language"], legacy_source: SOURCE,
        legacy_id: row["id"], legacy_url: category_legacy_url(row),
        created_at: valid_time(row["created_time"]), updated_at: valid_time(row["modified_time"])
      )
      category.save!(touch: false)
      stats[:categories] += 1
      category
    end

    def import_media
      analyzer.media_manifest.each do |entry|
        if entry[:external]
          stats[:external_media] += 1
          next
        elsif !entry[:exists]
          stats[:missing_media] += 1
          next
        end
        @media_by_source_path[entry[:old_path]] = upsert_media(entry)
      end
    end

    def upsert_media(entry)
      source = analyzer.joomla_root.join(entry[:old_path]).cleanpath
      digest = Digest::SHA256.file(source).hexdigest
      asset = MediaAsset.find_or_initialize_by(legacy_source: SOURCE, source_path: entry[:old_path])
      previous_digest = asset.sha256
      asset.assign_attributes(source_url: entry[:old_url], sha256: digest, source_byte_size: source.size, width: entry[:width], height: entry[:height])

      unless asset.file.attached? && previous_digest == digest
        if (duplicate = MediaAsset.where(sha256: digest).where.not(id: asset.id).detect { |candidate| candidate.file.attached? })
          asset.file.attach(duplicate.file.blob)
          asset.format = duplicate.format
          stats[:deduplicated_media] += 1
        else
          processed = optimize(source)
          asset.file.attach(io: File.open(processed[:path], "rb"), filename: processed[:filename], content_type: processed[:content_type])
          asset.format = processed[:format]
          stats[processed[:converted] ? :converted_to_webp : :kept_original] += 1
          FileUtils.rm_f(processed[:temporary]) if processed[:temporary]
        end
      end
      asset.save!
      stats[:media] += 1
      asset
    end

    def optimize(source)
      extension = source.extname.downcase
      return original_file(source) unless RASTER_TO_WEBP.include?(extension)

      temporary = Tempfile.new([ source.basename(source.extname).to_s, ".webp" ], Rails.root.join("tmp"))
      temporary.close
      ImageProcessing::Vips.source(source.to_s).convert("webp").saver(quality: 82, strip: true).call(destination: temporary.path)
      {
        path: temporary.path, temporary: temporary.path, filename: "#{source.basename(source.extname)}.webp",
        format: "webp", content_type: "image/webp", converted: true
      }
    rescue Vips::Error
      stats[:media_optimization_errors] += 1
      original_file(source)
    end

    def original_file(source)
      { path: source.to_s, filename: source.basename.to_s, format: source.extname.delete_prefix(".").downcase,
        content_type: Marcel::MimeType.for(source), converted: false, temporary: nil }
    end

    def import_articles
      analyzer.articles.each do |row|
        article = Article.find_or_initialize_by(legacy_source: SOURCE, legacy_id: row["id"])
        images = parse_json(row["images"])
        attributes = parse_json(row["attribs"])
        metadata = parse_json(row["metadata"])
        media = media_for_article(row)
        article.assign_attributes(
          title: row["title"], slug: conflict_free_slug(Article, row["alias"], article), excerpt: rewrite_html(row["introtext"]),
          body: rewrite_html(row["fulltext"]), category: category_for(row["catid"]),
          author: Author.find_by(legacy_source: SOURCE, legacy_id: row["created_by"]), status: article_status(row["state"]),
          featured: row["featured"].to_i == 1, position: row["ordering"].to_i, language: row["language"],
          views_count: row["hits"].to_i,
          published_at: valid_time(row["publish_up"]), seo_title: attributes["article_page_title"].presence,
          meta_description: row["metadesc"], meta_keywords: row["metakey"], robots: metadata["robots"],
          allow_indexing: !metadata["robots"].to_s.include?("noindex"), allow_follow: !metadata["robots"].to_s.include?("nofollow"),
          legacy_url: analyzer.article_url(row), visibility: row["access"].to_i <= 1 ? "public" : "admin",
          preview_image: media[:intro] || media[:main] || media[:fulltext], intro_image: media[:intro],
          fulltext_image: media[:fulltext], main_image: media[:main] || media[:fulltext],
          preview_image_alt: images["image_intro_alt"], preview_image_caption: images["image_intro_caption"],
          intro_image_alt: images["image_intro_alt"], intro_image_caption: images["image_intro_caption"],
          fulltext_image_alt: images["image_fulltext_alt"], fulltext_image_caption: images["image_fulltext_caption"],
          main_image_alt: attributes["helix_ultimate_image_alt_txt"],
          created_at: valid_time(row["created"]), updated_at: valid_time(row["modified"])
        )
        article.save!(touch: false)
        stats[:articles] += 1
      end
    end

    def import_redirects
      analyzer.table("redirect_links").each do |row|
        old_path = local_path(row["old_url"])
        new_path = local_path(row["new_url"])
        next if old_path.blank? || new_path.blank? || old_path == new_path
        redirect = LegacyRedirect.find_or_initialize_by(old_path: old_path)
        redirect.assign_attributes(legacy_source: SOURCE, new_path: new_path, http_status: 301)
        redirect.save!
        stats[:redirects] += 1
      end
    end

    def media_for_article(row)
      analyzer.media_references_for(row).each_with_object({}) do |reference, result|
        asset = @media_by_source_path[reference[:old_path]]
        next unless asset
        role = reference[:usage].to_s.split(":").first.to_sym
        result[role] ||= asset if %i[intro fulltext main].include?(role)
      end
    end

    def rewrite_html(html)
      result = html.to_s.dup
      @media_by_source_path.each do |old_path, asset|
        [ "https://www.goncharoff.pro/#{old_path}", "https://goncharoff.pro/#{old_path}", "/#{old_path}", old_path ].each do |old_url|
          result.gsub!(old_url, asset.public_path)
        end
      end
      result.gsub!(/(?<prefix>href\s*=\s*["'])(?<url>[^"']+)(?<suffix>["'])/i) do
        target = rewrite_internal_href(Regexp.last_match[:url])
        "#{Regexp.last_match[:prefix]}#{target}#{Regexp.last_match[:suffix]}"
      end
      result
    end

    def rewrite_internal_href(href)
      return href if href.start_with?("#", "mailto:", "tel:", "javascript:")
      decoded = CGI.unescapeHTML(href)
      if decoded.include?("index.php?") && decoded.include?("option=com_content") && (match = decoded.match(/[?&]id=(\d+)/))
        return @article_urls_by_legacy_id.fetch(match[1].to_i, href)
      end
      uri = URI.parse(URI::DEFAULT_PARSER.escape(decoded))
      return href if uri.host && !Analyzer::LOCAL_HOSTS.include?(uri.host.downcase)
      alias_name = File.basename(uri.path.to_s, File.extname(uri.path.to_s))
      target = @article_urls_by_alias[alias_name]
      target ? "#{target}#{uri.fragment.present? ? "##{uri.fragment}" : ""}" : href
    rescue URI::InvalidURIError
      href
    end

    def category_for(legacy_id) = Category.find_by(legacy_source: SOURCE, legacy_id: legacy_id)

    def category_legacy_url(row)
      path = row["path"].to_s.sub(%r{\Ablog/?}, "")
      path.present? ? "/#{path}" : nil
    end

    def article_status(state)
      { 1 => :published, 2 => :archived }.fetch(state.to_i, :draft)
    end

    def conflict_free_slug(model, desired, record)
      slug = desired.to_s.presence || "legacy-#{record.legacy_id}"
      conflict = model.where(slug: slug).where.not(id: record.id).exists?
      conflict ? "#{slug}-legacy-#{record.legacy_id}" : slug
    end

    def valid_time(value)
      return if value.blank? || value.start_with?("0000-00-00")
      Time.zone.parse(value)
    rescue ArgumentError
      nil
    end

    def parse_json(value)
      JSON.parse(value.presence || "{}")
    rescue JSON::ParserError
      {}
    end

    def local_path(value)
      return if value.blank?
      uri = URI.parse(value)
      return if uri.host && !Analyzer::LOCAL_HOSTS.include?(uri.host.downcase)
      path = uri.path.presence || value
      "/#{path.sub(%r{\A/+}, '')}".chomp("/")
    rescue URI::InvalidURIError
      nil
    end
  end
end
