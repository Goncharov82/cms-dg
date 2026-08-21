require "set"

class HtmlSourceFormatter
  BLOCK_TAGS = %w[
    address article aside blockquote details dialog div dl dt dd fieldset figcaption figure footer form
    h1 h2 h3 h4 h5 h6 header main nav ol p picture section summary table tbody td tfoot th thead tr ul li
  ].to_set.freeze
  RAW_BLOCK_PATTERN = %r{<(pre|script|style|textarea)\b[^>]*>.*?</\1>}im

  class << self
    def call(source)
      return source.to_s if source.blank?

      protected_blocks = []
      html = source.to_s.gsub(RAW_BLOCK_PATTERN) do |value|
        index = protected_blocks.length
        protected_blocks << value
        %(<dg-cms-raw data-index="#{index}" />)
      end

      depth = 0
      formatted = html.gsub(/>\s*</m, ">\n<").lines.filter_map do |line|
        content = line.strip
        next if content.empty?

        leading_close = content.match(%r{\A</([a-z0-9-]+)\b}i)
        display_depth = leading_close && BLOCK_TAGS.include?(leading_close[1].downcase) ? [depth - 1, 0].max : depth
        openings = content.scan(/<([a-z0-9-]+)\b[^>]*>/i).flatten.count { |tag| BLOCK_TAGS.include?(tag.downcase) }
        closings = content.scan(%r{</([a-z0-9-]+)\s*>}i).flatten.count { |tag| BLOCK_TAGS.include?(tag.downcase) }
        depth = [depth + openings - closings, 0].max
        "#{"  " * display_depth}#{content}"
      end.join("\n")

      formatted.gsub(/<dg-cms-raw data-index="(\d+)"\s*\/>/) { protected_blocks[Regexp.last_match(1).to_i] }
    end
  end
end
