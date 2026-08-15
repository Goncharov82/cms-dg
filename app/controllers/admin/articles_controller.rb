module Admin
  class ArticlesController < BaseController
    before_action :set_article, only: %i[show edit update destroy]

    def index
      @articles = Article.includes(:category).recent_first
    end

    def show; end

    def new
      @article = Article.new(status: :draft, allow_indexing: true, allow_follow: true, include_in_sitemap: true, use_seo_for_og: true, use_article_image_for_og: true)
    end

    def create
      @article = Article.new(article_params)
      apply_submit_action
      if @article.save
        redirect_to admin_article_path(@article), notice: @article.published? ? "Статья опубликована." : "Черновик сохранён."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      apply_submit_action
      if @article.update(article_params)
        redirect_to admin_article_path(@article), notice: "Статья обновлена."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @article.destroy!
      redirect_to admin_articles_path, notice: "Статья удалена."
    end

    private

    def set_article
      @article = Article.find(params[:id])
    end

    def article_params
      params.require(:article).permit(
        :title, :excerpt, :body, :status, :category_id, :published_at, :slug,
        :seo_title, :meta_description, :canonical_url, :allow_indexing,
        :allow_follow, :include_in_sitemap, :schema_type, :use_seo_for_og,
        :use_article_image_for_og, :twitter_card
      )
    end

    def apply_submit_action
      @article.status = params[:submit_action] if %w[draft published].include?(params[:submit_action])
    end
  end
end
