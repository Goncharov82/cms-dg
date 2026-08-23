class LegacyContentController < ApplicationController
  def show
    path = "/#{params[:legacy_path].to_s.sub(%r{\A/+}, '')}".chomp("/")
    if (article = article_scope.find_by(legacy_url: path) || article_for_path(path))
      article.increment!(:views_count) unless current_user
      @article = article
      @category = article.category
      load_sidebar
      render "articles/show"
    elsif (category = category_scope.find_by(legacy_url: path) || category_for_path(path))
      @category = category
      articles = category.articles.accessible_to(current_user).published
        .includes(:author, preview_image: { file_attachment: :blob }, intro_image: { file_attachment: :blob }, main_image: { file_attachment: :blob })
        .order(published_at: :desc, created_at: :desc)
      @per_page = 8
      @total_articles = articles.count
      @total_pages = [(@total_articles.to_f / @per_page).ceil, 1].max
      @current_page = params[:page].to_i.clamp(1, @total_pages)
      @articles = articles.offset((@current_page - 1) * @per_page).limit(@per_page)
      load_sidebar
      render "categories/show"
    elsif (redirect = LegacyRedirect.find_by(old_path: path))
      redirect_to redirect.new_path, status: redirect.http_status, allow_other_host: false
    else
      raise ActiveRecord::RecordNotFound
    end
  end

  private

  def load_sidebar
    @latest_articles = Article.accessible_to(current_user).published.order(published_at: :desc, created_at: :desc).limit(5)
  end

  def article_for_path(path)
    slug = path.split("/").last
    article_scope.includes(category: :parent).find_by(slug: slug)&.yield_self { |article| article.public_path == path ? article : nil }
  end

  def category_for_path(path)
    slug = path.split("/").last
    category_scope.find_by(slug: slug)&.yield_self { |category| category.public_path == path ? category : nil }
  end

  def article_scope
    scope = Article.accessible_to(current_user)
    current_user&.admin? ? scope : scope.published
  end

  def category_scope
    scope = Category.accessible_to(current_user)
    current_user&.admin? ? scope : scope.published
  end
end
