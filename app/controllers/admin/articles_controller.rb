module Admin
  class ArticlesController < BaseController
    before_action :set_article, only: %i[edit update destroy toggle_status]

    def index
      @categories = content_scope(Category).order(:name)
      @selected_category = @categories.find_by(id: params[:category]) if params[:category].present?
      @articles = content_scope(Article).includes(:category).recent_first
      @articles = @articles.where(category: @selected_category) if @selected_category
    end

    def new
      @article = Article.new(status: :draft, visibility: "public", allow_indexing: true, allow_follow: true, include_in_sitemap: true, use_seo_for_og: true, use_article_image_for_og: true)
    end

    def create
      @article = Article.new(article_params)
      apply_submit_action
      attach_uploaded_media
      if @article.save
        preserve_editor_timestamps
        redirect_to edit_admin_article_path(@article), notice: @article.published? ? "Статья опубликована." : "Черновик сохранён."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      apply_submit_action
      @article.assign_attributes(article_params)
      attach_uploaded_media
      if @article.save
        preserve_editor_timestamps
        redirect_to edit_admin_article_path(@article), notice: "Статья обновлена."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @article.destroy!
      redirect_to admin_articles_path, notice: "Статья удалена."
    end

    def toggle_status
      toggle_publication(@article, fallback_location: admin_articles_path)
    end

    private

    def set_article
      @article = content_scope(Article).find(params[:id])
    end

    def article_params
      enforce_access(params.require(:article).permit(
        :title, :excerpt, :body, :status, :visibility, :category_id, :author_id, :published_at, :slug,
        :seo_title, :meta_description, :canonical_url, :allow_indexing,
        :allow_follow, :include_in_sitemap, :schema_type, :use_seo_for_og,
        :use_article_image_for_og, :twitter_card, :featured, :created_at, :updated_at,
        :language, :meta_keywords, :robots, :preview_image_alt, :preview_image_caption,
        :intro_image_alt, :intro_image_caption, :fulltext_image_alt, :fulltext_image_caption,
        :main_image_alt, :main_image_caption
      ))
    end

    def attach_uploaded_media
      %i[preview intro fulltext main].each do |role|
        upload = params.dig(:article, "#{role}_image_upload")
        next unless upload.present?
        @article.public_send("#{role}_image=", MediaAssetIngestor.call(upload))
      end
    end

    def preserve_editor_timestamps
      timestamps = %i[created_at updated_at].filter_map do |name|
        value = params.dig(:article, name)
        next if value.blank?
        [ name, Time.zone.parse(value) ]
      rescue ArgumentError
        nil
      end.to_h
      @article.update_columns(timestamps) if timestamps.any?
    end

    def apply_submit_action
      @article.status = params[:submit_action] if %w[draft published].include?(params[:submit_action])
    end
  end
end
