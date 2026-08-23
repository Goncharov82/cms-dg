require "test_helper"

class HomeTest < ActionDispatch::IntegrationTest
  test "root page is available" do
    MenuItem.create!(label: "Тестовый раздел", slug: "test-section", item_type: :external,
      url: "/test-section", status: :published, visibility: "public", menu_name: "main")

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
    assert_select "footer.public-footer"
    assert_select "footer a[href='/test-section']", text: "Тестовый раздел"
    assert_select "footer a[href='https://www.youtube.com/@goncharoff_pro']", 1
    assert_select "footer", text: /ИП Гончаров Дмитрий Александрович/
    assert_select "footer", text: /© #{Time.current.year} Goncharoff\.pro/
  end
end
