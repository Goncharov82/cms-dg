# frozen_string_literal: true

require "cgi"
require "digest"
require "json"
require "nokogiri"
require "pathname"
require "set"
require "uri"
require "active_support/core_ext/enumerable"
require "active_support/core_ext/object/blank"
require_relative "dump_reader"

module LegacyJoomla
  class Analyzer
    TABLE_SUFFIXES = %w[
      categories content contentitem_tag_map fields fields_values menu redirect_links tags users
    ].freeze
    LOCAL_HOSTS = %w[goncharoff.pro www.goncharoff.pro].freeze
    IMAGE_EXTENSIONS = %w[.jpg .jpeg .png .gif .webp .svg .bmp .tif .tiff .avif].freeze

    attr_reader :root, :dump_path, :joomla_root, :prefix, :tables, :articles, :media_manifest

    def initialize(root: default_root)
      @root = Pathname(root).expand_path
      @dump_path = find_dump
      @joomla_root = find_joomla_root
      @prefix = detect_prefix
      @tables = DumpReader.new(dump_path, tables: TABLE_SUFFIXES.map { |name| "#{prefix}#{name}" }).read
      @articles = table("content").reject { |row| row["state"] == -2 }
      @sitemap_urls = load_sitemap_urls
      @media_manifest = build_media_manifest
    end

    def inventory
      content_categories = table("categories").select { |row| row["extension"] == "com_content" }
      used_author_ids = articles.map { |row| row["created_by"] }.to_set
      used_tag_ids = tag_links.map { |row| row["tag_id"] }.to_set
      used_fields = field_values.group_by { |row| row["field_id"] }.transform_values(&:length)
      states = articles.group_by { |row| row["state"] }.transform_values(&:length)

      {
        joomla_version: joomla_version,
        table_prefix: prefix,
        dump: dump_path.to_s,
        joomla_root: joomla_root.to_s,
        articles: articles.length,
        trashed_articles_skipped: table("content").count { |row| row["state"] == -2 },
        article_states: states,
        content_categories: content_categories.length,
        used_authors: table("users").count { |row| used_author_ids.include?(row["id"]) },
        tags: table("tags").count { |row| used_tag_ids.include?(row["id"]) },
        custom_fields: used_fields,
        menu_items: table("menu").count { |row| row["link"].to_s.include?("com_content") },
        redirects: table("redirect_links").length,
        sitemap_urls: @sitemap_urls.length,
        media: media_statistics
      }
    end

    def article_url(row)
      alias_name = row.fetch("alias").to_s
      exact = @sitemap_urls.select { |url| url_path(url).split("/").last == alias_name }
      return url_path(exact.first) if exact.one?

      category = category_by_id[row["catid"]]
      category_path = category&.fetch("path", "").to_s.sub(%r{\Ablog/?}, "")
      candidate = "/#{[ category_path, alias_name ].reject(&:empty?).join('/')}"
      @sitemap_urls.map { |url| url_path(url) }.find { |path| path == candidate } || candidate
    end

    def media_references_for(article)
      @media_references_by_article.fetch(article["id"], [])
    end

    def category_by_id = @category_by_id ||= table("categories").index_by { |row| row["id"] }
    def user_by_id = @user_by_id ||= table("users").index_by { |row| row["id"] }
    def tag_by_id = @tag_by_id ||= table("tags").index_by { |row| row["id"] }
    def fields_by_id = @fields_by_id ||= table("fields").index_by { |row| row["id"] }
    def field_values = table("fields_values").select { |row| article_ids.include?(row["item_id"].to_i) && row["value"].to_s.present? }
    def tag_links = table("contentitem_tag_map").select { |row| row["type_alias"] == "com_content.article" && article_ids.include?(row["content_item_id"].to_i) }
    def article_ids = @article_ids ||= articles.map { |row| row["id"] }.to_set

    def custom_values_for(article_id)
      field_values.select { |row| row["item_id"].to_i == article_id.to_i }.filter_map do |row|
        field = fields_by_id[row["field_id"]]
        next unless field
        field.merge("value" => row["value"])
      end
    end

    def tags_for(article_id)
      tag_links.select { |row| row["content_item_id"].to_i == article_id.to_i }.filter_map { |row| tag_by_id[row["tag_id"]] }
    end

    def table(suffix) = tables.fetch("#{prefix}#{suffix}")

    def write_analysis(path)
      Pathname(path).write(JSON.pretty_generate(inventory), mode: "w", encoding: Encoding::UTF_8)
    end

    def write_media_manifest(path)
      Pathname(path).write(JSON.pretty_generate(media_manifest), mode: "w", encoding: Encoding::UTF_8)
    end

    private

    def default_root = Pathname(__dir__).join("../..", "legacy_source")

    def find_dump
      candidates = root.children.select { |path| path.file? && %w[.sql .gz].include?(path.extname.downcase) }
      candidates.max_by(&:size) || raise("SQL dump not found in #{root}")
    end

    def find_joomla_root
      candidates = [ root.join("joomla"), *root.children.select(&:directory?) ]
      candidates.find { |path| path.join("configuration.php").file? && path.join("administrator").directory? } || raise("Joomla root not found in #{root}")
    end

    def detect_prefix
      dump_path.open("rb") do |file|
        file.each_line do |line|
          match = line.force_encoding(Encoding::UTF_8).match(/\ACREATE TABLE `([^`]+)content`/)
          return match[1] if match
        end
      end
      raise("Joomla table prefix not found")
    end

    def joomla_version
      manifest = Nokogiri::XML(joomla_root.join("administrator/manifests/files/joomla.xml").read)
      manifest.at_xpath("//version")&.text
    end

    def load_sitemap_urls
      path = joomla_root.join("sitemap.xml")
      return [] unless path.file?
      Nokogiri::XML(path.read).xpath("//*[local-name()='url']/*[local-name()='loc']").map(&:text)
    end

    def build_media_manifest
      @media_references_by_article = Hash.new { |hash, key| hash[key] = [] }
      entries = {}
      articles.each do |article|
        extract_article_media(article).each do |reference|
          @media_references_by_article[article["id"]] << reference
          key = reference[:external] ? reference[:old_url] : reference[:old_path]
          entry = entries[key] ||= inspect_media(reference)
          entry[:articles] << article["id"] unless entry[:articles].include?(article["id"])
          entry[:usages] << reference[:usage] unless entry[:usages].include?(reference[:usage])
        end
      end
      entries.values.sort_by { |entry| entry[:old_path].to_s }
    end

    def extract_article_media(article)
      references = []
      images = parse_json(article["images"])
      attributes = parse_json(article["attribs"])
      add_reference(references, images["image_intro"], "intro", alt: images["image_intro_alt"], caption: images["image_intro_caption"])
      add_reference(references, images["image_fulltext"], "fulltext", alt: images["image_fulltext_alt"], caption: images["image_fulltext_caption"])
      add_reference(references, attributes["helix_ultimate_image"], "main", alt: attributes["helix_ultimate_image_alt_txt"])

      %w[introtext fulltext].each do |field|
        fragment = Nokogiri::HTML.fragment(article[field].to_s)
        fragment.css("img").each do |image|
          %w[src data-src].each { |attribute| add_reference(references, image[attribute], "html:#{field}:#{attribute}", alt: image["alt"]) }
          %w[srcset data-srcset].each do |attribute|
            image[attribute].to_s.split(",").each { |item| add_reference(references, item.strip.split(/\s+/).first, "html:#{field}:#{attribute}", alt: image["alt"]) }
          end
        end
        fragment.css("[style*='background']").each do |node|
          node["style"].to_s.scan(/url\((?:'|")?([^)'\"]+)/i).flatten.each { |url| add_reference(references, url, "html:#{field}:background") }
        end
      end

      custom_values_for(article["id"]).each do |field|
        field["value"].to_s.scan(%r{(?:https?://[^\s"']+|/?(?:images|media)/[^\s"']+\.(?:jpe?g|png|gif|webp|svg))}i).each do |url|
          add_reference(references, url, "custom_field:#{field['name']}")
        end
      end
      references.uniq { |reference| [ reference[:old_url], reference[:usage] ] }
    end

    def add_reference(references, raw_url, usage, alt: nil, caption: nil)
      raw_url = CGI.unescapeHTML(raw_url.to_s.strip)
      return if raw_url.empty? || raw_url.start_with?("data:")
      normalized = normalize_url(raw_url)
      return unless normalized
      references << normalized.merge(usage: usage, alt: alt.to_s, caption: caption.to_s)
    end

    def normalize_url(raw_url)
      if raw_url.match?(%r{\Ahttps?://}i)
        uri = URI.parse(URI::DEFAULT_PARSER.escape(raw_url))
        if uri.host && !LOCAL_HOSTS.include?(uri.host.downcase)
          return { old_url: raw_url, old_path: nil, external: true }
        end
        path = CGI.unescape(uri.path.to_s)
      else
        path = CGI.unescape(raw_url.split(/[?#]/, 2).first)
      end
      path = path.tr("\\", "/").sub(%r{\A/+}, "")
      return if path.empty? || !IMAGE_EXTENSIONS.include?(File.extname(path).downcase)
      { old_url: raw_url, old_path: path, external: false }
    rescue URI::InvalidURIError
      nil
    end

    def inspect_media(reference)
      if reference[:external]
        return reference.merge(articles: [], usages: [], exists: nil, new_path: nil, new_format: nil, new_size: nil)
      end
      source = safe_source_path(reference[:old_path])
      stat = source&.file? ? source.stat : nil
      dimensions = image_dimensions(source)
      reference.merge(
        articles: [], usages: [], exists: !!stat, format: File.extname(reference[:old_path]).delete_prefix(".").downcase,
        size: stat&.size, width: dimensions&.first, height: dimensions&.last,
        new_path: nil, new_format: nil, new_size: nil
      )
    end

    def safe_source_path(relative_path)
      candidate = joomla_root.join(relative_path).cleanpath
      candidate.to_s.start_with?(joomla_root.to_s) ? candidate : nil
    end

    def image_dimensions(path)
      return unless path&.file?
      require "vips"
      image = Vips::Image.new_from_file(path.to_s, access: :sequential)
      [ image.width, image.height ]
    rescue LoadError, Vips::Error
      nil
    end

    def media_statistics
      local = media_manifest.reject { |entry| entry[:external] }
      archive_images = joomla_root.glob("**/*").select { |path| path.file? && IMAGE_EXTENSIONS.include?(path.extname.downcase) }
      {
        archive_images: archive_images.length, archive_image_bytes: archive_images.sum(&:size),
        referenced_files: local.sum { |entry| entry[:articles].length }, unique_images: local.length,
        existing: local.count { |entry| entry[:exists] }, missing: local.count { |entry| !entry[:exists] },
        external: media_manifest.count { |entry| entry[:external] }, source_bytes: local.sum { |entry| entry[:size].to_i }
      }
    end

    def parse_json(value)
      JSON.parse(value.presence || "{}")
    rescue JSON::ParserError
      {}
    end

    def url_path(url)
      path = URI(url).path
      path == "/" ? path : path.chomp("/")
    rescue URI::InvalidURIError
      url.to_s
    end
  end
end
