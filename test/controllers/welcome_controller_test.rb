require 'test_helper'

class WelcomeControllerTest < ActionController::TestCase
  test "should get welcome" do
    get :welcome
    assert_response :success
  end

  test "should get combine" do
    get :combine
    assert_response :success
  end

  test "should get stamp" do
    get :stamp
    assert_response :success
  end

  test "should get number" do
    get :number
    assert_response :success
  end

  test "should get tables" do
    get :tables
    assert_response :success
  end

  test "should get fonts" do
    get :fonts
    assert_response :success
  end

  test "should get bates" do
    get :bates
    assert_response :success
  end

end
