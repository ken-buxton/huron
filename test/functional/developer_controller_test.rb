require 'test_helper'

class DeveloperControllerTest < ActionController::TestCase
  test "should get Help" do
    get :Help
    assert_response :success
  end

end
