require "json"
require "fileutils"
require "digest"

namespace :content do
  desc "Create a backup and format stored article HTML for source-code editing"
  task format_article_html: :environment do
    articles = Article.where.not(body: [nil, ""]).order(:id).to_a
    timestamp = Time.current.strftime("%Y%m%d-%H%M%S")
    backup_directory = Rails.root.join("storage", "backups")
    backup_path = backup_directory.join("article-html-before-format-#{timestamp}.json")
    FileUtils.mkdir_p(backup_directory)

    backup = articles.map do |article|
      {
        id: article.id,
        title: article.title,
        body: article.body,
        body_sha256: Digest::SHA256.hexdigest(article.body),
        updated_at: article.updated_at&.iso8601
      }
    end
    File.write(backup_path, JSON.pretty_generate(backup))

    changed = 0
    Article.transaction do
      articles.each do |article|
        formatted = HtmlSourceFormatter.call(article.body)
        next if formatted == article.body

        article.update_columns(body: formatted)
        changed += 1
      end
    end

    puts "Backup: #{backup_path}"
    puts "Articles inspected: #{articles.length}"
    puts "Articles formatted: #{changed}"
  end
end
