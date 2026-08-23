require "test_helper"

class SiteSettingTest < ActiveSupport::TestCase
  test "stores site disabled state as a boolean setting" do
    assert_not SiteSetting.site_disabled?

    SiteSetting.site_disabled = "1"
    assert SiteSetting.site_disabled?

    SiteSetting.site_disabled = "0"
    assert_not SiteSetting.site_disabled?
  end
end
