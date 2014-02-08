require 'test_helper'

class AggregatesControllerTest < ActionController::TestCase
  setup do
    @aggregate = aggregates(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:aggregates)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create aggregate" do
    assert_difference('Aggregate.count') do
      post :create, aggregate: { aggregate_display_name: @aggregate.aggregate_display_name, aggregate_table_name: @aggregate.aggregate_table_name, creation_sql: @aggregate.creation_sql, dim_table_1: @aggregate.dim_table_1, dim_table_2: @aggregate.dim_table_2, dim_table_3: @aggregate.dim_table_3, dim_table_4: @aggregate.dim_table_4, dim_table_5: @aggregate.dim_table_5, dim_table_6: @aggregate.dim_table_6, dim_table_7: @aggregate.dim_table_7, dim_table_8: @aggregate.dim_table_8, fact_table_name: @aggregate.fact_table_name, search_order: @aggregate.search_order, update_sql: @aggregate.update_sql }
    end

    assert_redirected_to aggregate_path(assigns(:aggregate))
  end

  test "should show aggregate" do
    get :show, id: @aggregate
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @aggregate
    assert_response :success
  end

  test "should update aggregate" do
    put :update, id: @aggregate, aggregate: { aggregate_display_name: @aggregate.aggregate_display_name, aggregate_table_name: @aggregate.aggregate_table_name, creation_sql: @aggregate.creation_sql, dim_table_1: @aggregate.dim_table_1, dim_table_2: @aggregate.dim_table_2, dim_table_3: @aggregate.dim_table_3, dim_table_4: @aggregate.dim_table_4, dim_table_5: @aggregate.dim_table_5, dim_table_6: @aggregate.dim_table_6, dim_table_7: @aggregate.dim_table_7, dim_table_8: @aggregate.dim_table_8, fact_table_name: @aggregate.fact_table_name, search_order: @aggregate.search_order, update_sql: @aggregate.update_sql }
    assert_redirected_to aggregate_path(assigns(:aggregate))
  end

  test "should destroy aggregate" do
    assert_difference('Aggregate.count', -1) do
      delete :destroy, id: @aggregate
    end

    assert_redirected_to aggregates_path
  end
end
