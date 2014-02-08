require 'test_helper'

class AggregateDetailsControllerTest < ActionController::TestCase
  setup do
    @aggregate_detail = aggregate_details(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:aggregate_details)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create aggregate_detail" do
    assert_difference('AggregateDetail.count') do
      post :create, aggregate_detail: { agg_dim_table: @aggregate_detail.agg_dim_table, aggregate_table_name: @aggregate_detail.aggregate_table_name, order: @aggregate_detail.order }
    end

    assert_redirected_to aggregate_detail_path(assigns(:aggregate_detail))
  end

  test "should show aggregate_detail" do
    get :show, id: @aggregate_detail
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @aggregate_detail
    assert_response :success
  end

  test "should update aggregate_detail" do
    put :update, id: @aggregate_detail, aggregate_detail: { agg_dim_table: @aggregate_detail.agg_dim_table, aggregate_table_name: @aggregate_detail.aggregate_table_name, order: @aggregate_detail.order }
    assert_redirected_to aggregate_detail_path(assigns(:aggregate_detail))
  end

  test "should destroy aggregate_detail" do
    assert_difference('AggregateDetail.count', -1) do
      delete :destroy, id: @aggregate_detail
    end

    assert_redirected_to aggregate_details_path
  end
end
