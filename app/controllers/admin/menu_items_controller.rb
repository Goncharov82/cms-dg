module Admin
  class MenuItemsController < BaseController
    def new
      @menu_item = MenuItem.new(item_type: :page, status: :draft, visibility: "public", menu_name: "main")
    end

    def create
      @menu_item = MenuItem.new(menu_item_params)
      @menu_item.status = params[:submit_action] == "published" ? :published : :draft
      @menu_item.url = generated_url if @menu_item.url.blank? && !@menu_item.external?
      if @menu_item.save
        redirect_to admin_site_menu_path, notice: "Пункт меню сохранён"
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def generated_url
      prefix = @menu_item.page? ? "" : "/blog"
      "#{prefix}/#{@menu_item.slug}".gsub(%r{//+}, "/")
    end

    def menu_item_params
      params.require(:menu_item).permit(:label, :slug, :item_type, :target_label, :url, :description,
        :visibility, :menu_name, :parent_label, :position, :open_new_tab, :nofollow, :hide_mobile)
    end
  end
end
