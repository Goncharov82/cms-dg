class ApplicationController < ActionController::Base
  before_action :enforce_site_availability

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_user, :authenticated?

  private

  def enforce_site_availability
    return unless SiteSetting.site_disabled?
    return if site_availability_bypass?
    return if current_user&.admin?

    response.set_header("X-Robots-Tag", "noindex, nofollow, noarchive")
    render "shared/site_disabled", layout: "maintenance", status: :service_unavailable
  end

  def site_availability_bypass?
    request.path == "/admin" ||
      request.path.start_with?("/admin/") ||
      request.path == login_path ||
      request.path == session_path ||
      request.path == rails_health_check_path
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def authenticated?
    current_user.present?
  end

  def require_authentication
    return if authenticated?

    session[:return_to_after_authenticating] = request.fullpath
    redirect_to login_path, alert: "Войдите, чтобы продолжить."
  end
end
