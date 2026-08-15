module Admin
  class CategoriesController < BaseController
    def index
      @categories = Category.left_joins(:articles).group(:id).order(:name).select("categories.*, COUNT(articles.id) AS articles_count")
    end

    def new
      @category = Category.new(
        status: :draft, visibility: "public", articles_sort: "newest", articles_per_page: 12,
        show_description: true, show_image: true, use_for_open_graph: true
      )
    end

    def create
      @category = Category.new(category_params)
      @category.status = params[:submit_action] if %w[draft published].include?(params[:submit_action])

      if @category.save
        redirect_to admin_categories_path, notice: @category.published? ? "Категория опубликована." : "Черновик категории сохранён."
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def category_params
      params.require(:category).permit(
        :name, :slug, :parent_id, :short_description, :description, :image, :status,
        :visibility, :articles_sort, :articles_per_page, :show_description, :show_image,
        :use_for_open_graph, :seo_title, :meta_description, :canonical_url
      )
    end
  end
end
