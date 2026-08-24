require "nokogiri"
require "set"
require "uri"

module AuditHtml
  SHORTCODE_PATTERN = /\{\/?(?:gallery|loadposition|emailcloak)(?:\s*=\s*[^}]*)?(?:\s+[^}]*)?\}/i
  EVENT_ATTRIBUTE_PATTERN = /\Aon[a-z0-9_-]+\z/i
  IMAGE_EXTENSIONS = {
    jpg: ".jpg",
    jpeg: ".jpeg",
    png: ".png",
    webp: ".webp"
  }.freeze

  module_function

  def run
    totals = {
      script: counter,
      event_attribute: counter,
      javascript_link: counter,
      iframe: counter,
      table: counter,
      inline_style: counter,
      joomla_shortcode: counter,
      parse_error: counter
    }
    event_names = grouped_counter
    iframe_domains = grouped_counter
    image_extensions = IMAGE_EXTENSIONS.keys.index_with { grouped_entry }
    inspected = 0

    Article.find_each do |article|
      inspected += 1
      html_parts = [ article.excerpt, article.body ].compact_blank
      fragments, parse_errors = parse_fragments(html_parts)

      record(totals[:script], fragments.sum { |fragment| fragment.css("script").count })
      record(totals[:javascript_link], javascript_link_count(fragments))
      record(totals[:table], fragments.sum { |fragment| fragment.css("table").count })
      record(totals[:inline_style], fragments.sum { |fragment| fragment.css("[style]").count })
      record(totals[:joomla_shortcode], html_parts.sum { |html| html.scan(SHORTCODE_PATTERN).count })
      record(totals[:parse_error], parse_errors)

      record_event_attributes(article.id, fragments, totals[:event_attribute], event_names)
      record_iframes(article.id, fragments, totals[:iframe], iframe_domains)
      record_image_extensions(article.id, fragments, image_extensions)
    end

    puts "Проверены поля: Article#excerpt и Article#body"
    puts "Статей проверено: #{inspected}"
    puts
    print_table("Основные проверки", [ "Проверка", "Статей", "Совпадений" ], main_rows(totals))
    print_table("Атрибуты событий", [ "Атрибут", "Статей", "Совпадений" ], grouped_rows(event_names))
    print_table("Домены iframe", [ "Домен", "Статей", "Iframe" ], grouped_rows(iframe_domains))
    print_table("Ссылки на изображения", [ "Расширение", "Статей", "Ссылок" ], image_rows(image_extensions))
  end

  def counter
    { articles: 0, occurrences: 0 }
  end

  def grouped_counter
    Hash.new { |hash, key| hash[key] = grouped_entry }
  end

  def grouped_entry
    { article_ids: Set.new, occurrences: 0 }
  end

  def parse_fragments(html_parts)
    fragments = []
    errors = 0

    html_parts.each do |html|
      fragments << Nokogiri::HTML5.fragment(html)
    rescue StandardError
      errors += 1
    end

    [ fragments, errors ]
  end

  def record(target, count)
    return if count.zero?

    target[:articles] += 1
    target[:occurrences] += count
  end

  def javascript_link_count(fragments)
    fragments.sum do |fragment|
      fragment.css("a[href], area[href]").count do |node|
        normalized = node["href"].to_s.gsub(/[\u0000-\u0020]+/, "")
        normalized.match?(/\Ajavascript:/i)
      end
    end
  end

  def record_event_attributes(article_id, fragments, total, grouped)
    names = fragments.flat_map do |fragment|
      fragment.css("*").flat_map(&:attribute_nodes).filter_map do |attribute|
        attribute.name.downcase if attribute.name.match?(EVENT_ATTRIBUTE_PATTERN)
      end
    end
    record(total, names.count)
    names.each do |name|
      grouped[name][:article_ids] << article_id
      grouped[name][:occurrences] += 1
    end
  end

  def record_iframes(article_id, fragments, total, grouped)
    iframes = fragments.flat_map { |fragment| fragment.css("iframe").to_a }
    record(total, iframes.count)
    iframes.each do |iframe|
      domain = iframe_domain(iframe["src"])
      grouped[domain][:article_ids] << article_id
      grouped[domain][:occurrences] += 1
    end
  end

  def iframe_domain(source)
    return "(без src)" if source.blank?

    value = source.strip
    uri = URI.parse(value.start_with?("//") ? "https:#{value}" : value)
    return uri.host.downcase if uri.host.present?
    return "(относительный URL)" if uri.scheme.blank?

    "(схема: #{uri.scheme.downcase})"
  rescue URI::InvalidURIError
    "(некорректный URL)"
  end

  def record_image_extensions(article_id, fragments, grouped)
    fragments.flat_map { |fragment| image_urls(fragment) }.each do |url|
      extension = image_extension(url)
      next unless extension

      grouped[extension][:article_ids] << article_id
      grouped[extension][:occurrences] += 1
    end
  end

  def image_urls(fragment)
    urls = []
    fragment.css("img, source").each do |node|
      %w[src data-src].each { |attribute| urls << node[attribute] if node[attribute].present? }
      %w[srcset data-srcset].each do |attribute|
        urls.concat(srcset_urls(node[attribute])) if node[attribute].present?
      end
    end
    fragment.css("a[href]").each do |node|
      urls << node["href"] if image_extension(node["href"])
    end
    urls
  end

  def srcset_urls(srcset)
    srcset.to_s.split(",").filter_map { |candidate| candidate.strip.split(/\s+/, 2).first.presence }
  end

  def image_extension(url)
    path = URI.parse(url.to_s.strip).path
    path ||= ""
    IMAGE_EXTENSIONS.each_key do |extension|
      return extension if path.match?(/\.#{Regexp.escape(extension.to_s)}\z/i)
    end
    nil
  rescue URI::InvalidURIError
    clean_path = url.to_s.split(/[?#]/, 2).first
    IMAGE_EXTENSIONS.each_key.find { |extension| clean_path.match?(/\.#{Regexp.escape(extension.to_s)}\z/i) }
  end

  def main_rows(totals)
    {
      "Тег script" => totals[:script],
      "Атрибуты on*" => totals[:event_attribute],
      "Ссылки javascript:" => totals[:javascript_link],
      "Тег iframe" => totals[:iframe],
      "Тег table" => totals[:table],
      "Атрибут style=" => totals[:inline_style],
      "Шорткоды Joomla" => totals[:joomla_shortcode],
      "Ошибки разбора HTML" => totals[:parse_error]
    }.map { |label, values| [ label, values[:articles], values[:occurrences] ] }
  end

  def grouped_rows(grouped)
    rows = grouped.map do |label, values|
      [ label, values[:article_ids].count, values[:occurrences] ]
    end
    rows.sort_by { |label, _, occurrences| [ -occurrences, label ] }
  end

  def image_rows(grouped)
    IMAGE_EXTENSIONS.map do |extension, label|
      values = grouped.fetch(extension)
      [ label, values[:article_ids].count, values[:occurrences] ]
    end
  end

  def print_table(title, headers, rows)
    rows = [ [ "(нет)", 0, 0 ] ] if rows.empty?
    widths = headers.each_index.map do |index|
      ([ headers[index].length ] + rows.map { |row| row[index].to_s.length }).max
    end

    puts title
    puts table_line(headers, widths)
    puts widths.map { |width| "-" * (width + 2) }.join("+").prepend("+").concat("+")
    rows.each { |row| puts table_line(row, widths) }
    puts
  end

  def table_line(values, widths)
    cells = values.each_with_index.map { |value, index| " #{value.to_s.ljust(widths[index])} " }
    cells.join("|").prepend("|").concat("|")
  end
end

desc "Audit stored article HTML and print aggregate findings"
task audit_html: :environment do
  AuditHtml.run
end
