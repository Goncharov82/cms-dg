module Admin
  class SiteMenuController < BaseController
    def show
      @menu_items = content_scope(MenuItem).where(menu_name: "main").order(:position, :created_at)
    end
  end
end
