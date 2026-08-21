module Admin
  class SettingsController < BaseController
    def show
      @tiptap_release = TiptapReleaseChecker.call
      @codemirror_release = CodeMirrorReleaseChecker.call
    end

    def check_updates
      checker, name = if params[:component] == "codemirror"
        [CodeMirrorReleaseChecker, "CodeMirror"]
      else
        [TiptapReleaseChecker, "Tiptap"]
      end
      release = checker.call(force: true)
      message = if release[:error].present?
        release[:error]
      elsif release[:current]
        "Установлена актуальная версия #{name} #{release[:installed_version]}."
      else
        "Доступна новая версия #{name} #{release[:latest_version]}."
      end
      redirect_to admin_settings_path, notice: message
    end
  end
end
