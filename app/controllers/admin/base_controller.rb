module Admin
  class BaseController < ApplicationController
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
