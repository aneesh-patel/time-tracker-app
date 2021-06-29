require "test_helper"

class AuthenticationControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get authentication_create_url
    assert_response :success
  end
end
