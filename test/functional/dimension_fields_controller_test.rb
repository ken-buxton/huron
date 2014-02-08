require 'test_helper'

class DimensionFieldsControllerTest < ActionController::TestCase
  setup do
    @dimension_field = dimension_fields(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:dimension_fields)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create dimension_field" do
    assert_difference('DimensionField.count') do
      post :create, dimension_field: { compare_as: @dimension_field.compare_as, display_order: @dimension_field.display_order, field_display_name: @dimension_field.field_display_name, field_name: @dimension_field.field_name, is_primary_key: @dimension_field.is_primary_key, table_name: @dimension_field.table_name }
    end

    assert_redirected_to dimension_field_path(assigns(:dimension_field))
  end

  test "should show dimension_field" do
    get :show, id: @dimension_field
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @dimension_field
    assert_response :success
  end

  test "should update dimension_field" do
    put :update, id: @dimension_field, dimension_field: { compare_as: @dimension_field.compare_as, display_order: @dimension_field.display_order, field_display_name: @dimension_field.field_display_name, field_name: @dimension_field.field_name, is_primary_key: @dimension_field.is_primary_key, table_name: @dimension_field.table_name }
    assert_redirected_to dimension_field_path(assigns(:dimension_field))
  end

  test "should destroy dimension_field" do
    assert_difference('DimensionField.count', -1) do
      delete :destroy, id: @dimension_field
    end

    assert_redirected_to dimension_fields_path
  end
end
