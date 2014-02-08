require 'test_helper'

class FactFieldsControllerTest < ActionController::TestCase
  setup do
    @fact_field = fact_fields(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:fact_fields)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create fact_field" do
    assert_difference('FactField.count') do
      post :create, fact_field: { dimension: @fact_field.dimension, display_order: @fact_field.display_order, fact_type: @fact_field.fact_type, field_display_name: @fact_field.field_display_name, field_name: @fact_field.field_name, field_type: @fact_field.field_type, table_name: @fact_field.table_name }
    end

    assert_redirected_to fact_field_path(assigns(:fact_field))
  end

  test "should show fact_field" do
    get :show, id: @fact_field
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @fact_field
    assert_response :success
  end

  test "should update fact_field" do
    put :update, id: @fact_field, fact_field: { dimension: @fact_field.dimension, display_order: @fact_field.display_order, fact_type: @fact_field.fact_type, field_display_name: @fact_field.field_display_name, field_name: @fact_field.field_name, field_type: @fact_field.field_type, table_name: @fact_field.table_name }
    assert_redirected_to fact_field_path(assigns(:fact_field))
  end

  test "should destroy fact_field" do
    assert_difference('FactField.count', -1) do
      delete :destroy, id: @fact_field
    end

    assert_redirected_to fact_fields_path
  end
end
