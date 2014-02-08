require 'test_helper'

class LoadIndicesControllerTest < ActionController::TestCase
  test "should get doit" do
    get :doit
    assert_response :success
  end

end
