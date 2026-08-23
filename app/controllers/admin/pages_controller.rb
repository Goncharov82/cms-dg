module Admin
  class PagesController < BaseController
    before_action :set_page, only: %i[edit update toggle_status]
    def index
      @pages = content_scope(Page).order(updated_at: :desc)
    end

    def new
      @page = Page.new(
        title: "Главная страница",
        slug: "/",
        status: :draft,
        visibility: "public",
        include_in_sitemap: true,
        allow_indexing: true,
        body_html: "<main class=\"home-page\">\n  <section class=\"hero\">\n    <p class=\"eyebrow\">GONCHAROFF.PRO</p>\n    <h1>Блог о блогинге и монетизации</h1>\n    <a href=\"/reviews\">Читать статьи</a>\n  </section>\n</main>"
      )
    end

    def create
      @page = Page.new(page_params)
      @page.status = params[:submit_action] if %w[draft published].include?(params[:submit_action])

      if @page.save
        redirect_to admin_pages_path, notice: @page.published? ? "Страница опубликована." : "Черновик страницы сохранён."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      @page.assign_attributes(page_params)
      @page.status = params[:submit_action] if %w[draft published].include?(params[:submit_action])
      if @page.save
        redirect_to edit_admin_page_path(@page), notice: "Страница обновлена."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def toggle_status
      toggle_publication(@page, fallback_location: admin_pages_path)
    end

    private

    def set_page = @page = content_scope(Page).find(params[:id])

    def page_params
      enforce_access(params.require(:page).permit(
        :title, :slug, :body_html, :body_css, :body_js, :status, :visibility,
        :seo_title, :meta_description, :canonical_url, :include_in_sitemap, :allow_indexing
      ))
    end
  end
end
