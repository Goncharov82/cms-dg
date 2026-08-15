require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "root page is available" do
    get root_path

    assert_response :success
    assert_select "h1", "Goncharoff.pro"
  end
end
