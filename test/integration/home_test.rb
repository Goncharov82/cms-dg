require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "root page is available" do
    get root_path

    assert_response :success
    assert_select "h1", "Goncharoff.pro"
    assert_select "img[alt='Goncharoff.pro']"
    assert_select "nav.public-nav a", 6
    assert_select "[data-home-slider-target='slide']", 4
    assert_select "a.home-slider__link[href^='/lp/ai-prompt.html']", 1
    assert_select "a.home-slider__link[href^='/markirovka.html']", 1
    assert_select "a.home-slider__link[href^='/lp/myreviews.html']", 1
    assert_select "a.home-slider__link[href^='/ai/kak-poluchit-50-skidku-na-vps-server-timeweb-cloud']", 1
  end
end
