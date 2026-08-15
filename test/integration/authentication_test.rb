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
end
