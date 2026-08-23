module Admin
  class DashboardController < BaseController
    def index
      articles = content_scope(Article)
      @stats = [
        { label: "Статьи", value: articles.count, icon: :page, tone: :orange },
        { label: "Черновики", value: articles.draft.count, icon: :edit, tone: :slate },
        { label: "Категории", value: content_scope(Category).count, icon: :folder, tone: :orange },
        { label: "Медиафайлы", value: ActiveStorage::Blob.count, icon: :image, tone: :slate }
      ]
      @recent_articles = articles.includes(:category).recent_first.limit(5)
    end
  end
end
