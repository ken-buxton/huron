require 'test_helper'

class LoadAggsControllerTest < ActionController::TestCase
  test "should get doit" do
    get :doit
    assert_response :success
  end

end
