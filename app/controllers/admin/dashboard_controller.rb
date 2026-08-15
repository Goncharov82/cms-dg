module Admin
  class DashboardController < BaseController
    def index
      @stats = [
        { label: "Статьи", value: Article.count, icon: :page, tone: :orange },
        { label: "Черновики", value: Article.draft.count, icon: :edit, tone: :slate },
        { label: "Категории", value: Category.count, icon: :folder, tone: :orange },
        { label: "Медиафайлы", value: ActiveStorage::Blob.count, icon: :image, tone: :slate }
      ]
      @recent_articles = Article.includes(:category).recent_first.limit(5)
    end
  end
end
