module Admin
  class AnalyticsController < BaseController
    def show
      articles = content_scope(Article)
      @published_articles_count = articles.published.count
      @draft_articles_count = articles.draft.count
    end
  end
end
