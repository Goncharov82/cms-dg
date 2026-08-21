module Admin
  class MenuItemsController < BaseController
    before_action :set_menu_item, only: %i[edit update toggle_status]
    def new
      @menu_item = MenuItem.new(item_type: :page, status: :draft, visibility: "public", menu_name: "main")
    end

    def create
      @menu_item = MenuItem.new(menu_item_params)
      apply_submit_action
      @menu_item.url = generated_url unless @menu_item.external?
      if @menu_item.save
        redirect_to admin_site_menu_path, notice: "Пункт меню сохранён"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit; end

    def update
      @menu_item.assign_attributes(menu_item_params)
      apply_submit_action
      @menu_item.url = generated_url unless @menu_item.external?
      if @menu_item.save
        redirect_to admin_site_menu_path, notice: "Пункт меню обновлён"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def toggle_status
      toggle_publication(@menu_item, fallback_location: admin_site_menu_path)
    end

    private

    def set_menu_item = @menu_item = content_scope(MenuItem).find(params[:id])

    def generated_url
      return "/#{@menu_item.slug}" unless @menu_item.category?

      @menu_item.target_category&.public_path || "/#{@menu_item.slug}"
    end

    def apply_submit_action
      @menu_item.status = :draft if params[:submit_action] == "draft"
    end

    def menu_item_params
      enforce_access(params.require(:menu_item).permit(:label, :slug, :item_type, :target_id, :target_label, :url, :description, :status,
        :visibility, :menu_name, :parent_label, :position, :open_new_tab, :nofollow, :hide_mobile))
    end
  end
end
