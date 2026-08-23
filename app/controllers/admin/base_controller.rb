module Admin
  class BaseController < ApplicationController
    PER_PAGE_OPTIONS = %w[20 50 100 500 all].freeze

    layout "admin"
    before_action :require_authentication

    helper_method :content_scope

    private

    def content_scope(model)
      model.accessible_to(current_user)
    end

    def enforce_access(attributes)
      attributes[:visibility] = "public" unless current_user.admin?
      attributes
    end

    def paginate_collection(scope)
      requested_size = params[:per_page].to_s
      @per_page = PER_PAGE_OPTIONS.include?(requested_size) ? requested_size : "20"

      count = scope.except(:select, :order).count
      @collection_total = count.is_a?(Hash) ? count.size : count
      @total_pages = @per_page == "all" ? 1 : [(@collection_total.to_f / @per_page.to_i).ceil, 1].max
      @current_page = params[:page].to_i.clamp(1, @total_pages)

      if @per_page == "all"
        @page_start = @collection_total.zero? ? 0 : 1
        @page_end = @collection_total
        scope
      else
        offset = (@current_page - 1) * @per_page.to_i
        @page_start = @collection_total.zero? ? 0 : offset + 1
        @page_end = [offset + @per_page.to_i, @collection_total].min
        scope.offset(offset).limit(@per_page.to_i)
      end
    end

    def toggle_publication(record, fallback_location:)
      publishing = !record.published?
      attributes = { status: publishing ? :published : :draft }
      if publishing && record.respond_to?(:published_at) && record.published_at.blank?
        attributes[:published_at] = Time.current
      end
      record.update!(attributes)
      label = record.published? ? "Опубликовано" : "Не опубликовано"
      redirect_back fallback_location:, notice: "Состояние изменено: #{label}."
    end
  end
end
