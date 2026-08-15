require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email and supports roles" do
    user = User.create!(
      email: " Admin@Example.COM ",
      password: "a-secure-password",
      password_confirmation: "a-secure-password",
      role: :admin
    )

    assert_equal "admin@example.com", user.email
    assert_predicate user, :admin?
  end

  test "requires unique email regardless of case" do
    User.create!(email: "editor@example.com", password: "a-secure-password", role: :editor)
    duplicate = User.new(email: "EDITOR@example.com", password: "a-secure-password", role: :editor)

    assert_not duplicate.valid?
    assert_predicate duplicate.errors[:email], :present?
  end
end
