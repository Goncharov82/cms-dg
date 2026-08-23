require Rails.root.join("lib/legacy_joomla/analyzer")
require Rails.root.join("lib/legacy_joomla/importer")
require Rails.root.join("lib/legacy_joomla/verifier")
require Rails.root.join("lib/legacy_joomla/reporter")

namespace :legacy do
  desc "Analyze the read-only Joomla source without writing CMS records"
  task analyze: :environment do
    analyzer = LegacyJoomla::Analyzer.new
    FileUtils.mkdir_p(Rails.root.join("migration_reports"))
    analyzer.write_analysis(Rails.root.join("migration_reports/joomla_inventory.json"))
    analyzer.write_media_manifest(Rails.root.join("migration_reports/media_manifest.json"))
    puts JSON.pretty_generate(analyzer.inventory)
  end

  desc "Idempotently import Joomla content and referenced media"
  task import: :environment do
    puts JSON.pretty_generate(LegacyJoomla::Importer.new.call)
  end

  desc "Verify imported Joomla content"
  task verify: :environment do
    result = LegacyJoomla::Verifier.new.call
    puts JSON.pretty_generate(result)
    abort("Legacy verification failed") unless result[:ok]
  end

  desc "Write the final migration report and enriched media manifest"
  task report: :environment do
    FileUtils.mkdir_p(Rails.root.join("migration_reports"))
    LegacyJoomla::Reporter.new.write(
      report_path: Rails.root.join("migration_report.md"),
      manifest_path: Rails.root.join("migration_reports/media_manifest.json")
    )
    puts "Wrote migration_report.md and migration_reports/media_manifest.json"
  end
end
