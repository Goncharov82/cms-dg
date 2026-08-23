require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(
      email: "admin@example.com",
      password: "a-secure-password",
      password_confirmation: "a-secure-password",
      role: :admin
    )
  end

  test "admin redirects unauthenticated visitor to login" do
    get admin_root_path

    assert_redirected_to login_path
  end

  test "administrator can sign in and open dashboard" do
    post session_path, params: { email: @admin.email, password: "a-secure-password" }

    assert_redirected_to admin_root_path
    follow_redirect!
    assert_response :success
    assert_select "h1", "Дашборд"
  end

  test "invalid credentials do not create a session" do
    post session_path, params: { email: @admin.email, password: "wrong-password" }

    assert_response :unprocessable_content
    assert_select "[role=status]", text: /Неверный email/
  end

  test "authenticated user can sign out" do
    post session_path, params: { email: @admin.email, password: "a-secure-password" }
    delete session_path

    assert_redirected_to login_path
    get admin_root_path
    assert_redirected_to login_path
  end

  test "disabled site is hidden from visitors but remains available to administrator" do
    SiteSetting.site_disabled = true

    get root_path
    assert_response :service_unavailable
    assert_equal "noindex, nofollow, noarchive", response.headers["X-Robots-Tag"]
    assert_select "meta[name='robots'][content='noindex,nofollow,noarchive']"
    assert_select "h1", "Сайт временно недоступен"

    get login_path
    assert_response :success
    post session_path, params: { email: @admin.email, password: "a-secure-password" }
    assert_redirected_to admin_root_path

    get root_path
    assert_response :success
    assert_select "h1", "Goncharoff.pro"
  end

  test "administrator can change public site availability in settings" do
    post session_path, params: { email: @admin.email, password: "a-secure-password" }

    patch admin_settings_path, params: { site_disabled: "1" }
    assert_redirected_to admin_settings_path(anchor: "general-settings")
    assert SiteSetting.site_disabled?

    patch admin_settings_path, params: { site_disabled: "0" }
    assert_redirected_to admin_settings_path(anchor: "general-settings")
    assert_not SiteSetting.site_disabled?
  end
end
