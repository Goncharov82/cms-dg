require "net/http"
require "json"

class CodeMirrorReleaseChecker
  INSTALLED_VERSION = "6.0.2"
  PACKAGE_URL = "https://www.npmjs.com/package/codemirror"
  API_URL = "https://registry.npmjs.org/codemirror/latest"
  CACHE_KEY = "cms/settings/codemirror-release/v1"
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
      request["Accept"] = "application/json"
      request["User-Agent"] = "DG-CMS-CodeMirror-Update-Checker"
      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, open_timeout: 5, read_timeout: 8) { |http| http.request(request) }
      raise "npm Registry вернул HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      payload = JSON.parse(response.body)
      latest = payload.fetch("version")
      {
        installed_version: INSTALLED_VERSION,
        latest_version: latest,
        current: Gem::Version.new(INSTALLED_VERSION) >= Gem::Version.new(latest),
        release_url: PACKAGE_URL,
        published_at: nil,
        checked_at: Time.current,
        error: nil
      }
    rescue StandardError => error
      Rails.logger.warn("CodeMirror update check failed: #{error.class}: #{error.message}")
      {
        installed_version: INSTALLED_VERSION,
        latest_version: nil,
        current: nil,
        release_url: PACKAGE_URL,
        published_at: nil,
        checked_at: Time.current,
        error: "Не удалось связаться с npm Registry. Повторная автоматическая проверка будет выполнена позже."
      }
    end
  end
end
