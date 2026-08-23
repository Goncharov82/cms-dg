require "net/http"
require "json"

class TiptapReleaseChecker
  INSTALLED_VERSION = "3.30.1"
  REPOSITORY_URL = "https://github.com/ueberdosis/tiptap"
  RELEASES_URL = "#{REPOSITORY_URL}/releases"
  API_URL = "https://api.github.com/repos/ueberdosis/tiptap/releases/latest"
  CACHE_KEY = "cms/settings/tiptap-release/v1"
  CHECK_INTERVAL = 1.week
  ERROR_RETRY_INTERVAL = 1.hour

  class << self
    def call(force: false)
      cached = Rails.cache.read(CACHE_KEY)
      return cached if cached.present? && !force

      result = fetch_release
      Rails.cache.write(CACHE_KEY, result, expires_in: result[:error].present? ? ERROR_RETRY_INTERVAL : CHECK_INTERVAL)
      result
    end

    private

    def fetch_release
      uri = URI(API_URL)
      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/vnd.github+json"
      request["User-Agent"] = "DG-CMS-Tiptap-Update-Checker"
      request["X-GitHub-Api-Version"] = "2022-11-28"
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 8) { |http| http.request(request) }
      raise "GitHub вернул HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      payload = JSON.parse(response.body)
      latest = payload.fetch("tag_name").delete_prefix("v")
      {
        installed_version: INSTALLED_VERSION,
        latest_version: latest,
        current: Gem::Version.new(INSTALLED_VERSION) >= Gem::Version.new(latest),
        release_url: payload["html_url"].presence || RELEASES_URL,
        published_at: payload["published_at"],
        checked_at: Time.current,
        error: nil
      }
    rescue StandardError => error
      Rails.logger.warn("Tiptap update check failed: #{error.class}: #{error.message}")
      {
        installed_version: INSTALLED_VERSION,
        latest_version: nil,
        current: nil,
        release_url: RELEASES_URL,
        published_at: nil,
        checked_at: Time.current,
        error: "Не удалось связаться с GitHub. Повторная автоматическая проверка будет выполнена позже."
      }
    end
  end
end
