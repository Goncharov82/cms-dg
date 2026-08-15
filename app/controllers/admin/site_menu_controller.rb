module Admin
  class SiteMenuController < BaseController
    def show
      @menu_items = MenuItem.where(menu_name: "main").order(:position, :created_at)
    end
  end
end
