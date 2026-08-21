class CheckTiptapUpdatesJob < ApplicationJob
  queue_as :default

  def perform
    TiptapReleaseChecker.call(force: true)
  end
end
