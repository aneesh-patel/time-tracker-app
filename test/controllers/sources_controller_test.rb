require "test_helper"

class SourcesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get sources_index_url
    assert_response :success
  end

  test "should get create" do
    get sources_create_url
    assert_response :success
  end

  test "should get show" do
    get sources_show_url
    assert_response :success
  end

  test "should get delete" do
    get sources_delete_url
    assert_response :success
  end

  test "should get update" do
    get sources_update_url
    assert_response :success
  end
end
