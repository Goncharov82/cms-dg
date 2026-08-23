module Admin
  class SiteMenuController < BaseController
    def show
      scope = content_scope(MenuItem).where(menu_name: "main").order(:position, :created_at)
      @menu_items = paginate_collection(scope)
    end
  end
end
