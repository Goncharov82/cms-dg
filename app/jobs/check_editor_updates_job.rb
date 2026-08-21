class CheckEditorUpdatesJob < ApplicationJob
  queue_as :default

  def perform
    TiptapReleaseChecker.call(force: true)
    CodeMirrorReleaseChecker.call(force: true)
  end
end
