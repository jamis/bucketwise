require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  test "new should render login page" do
    get :new
    assert_response :success
    assert_template "sessions/new"
  end

  test "create should redirect to login page on bad user name" do
    post :create, :user_name => "jimjim", :password => "whatever"
    assert_redirected_to new_session_url
    assert @response.session[:user_id].blank?
  end

  test "create should redirect to login page on bad password" do
    post :create, :user_name => "john", :password => "whatever"
    assert_redirected_to new_session_url
    assert @response.session[:user_id].blank?
  end

  test "create should redirect to subscription page on success when only one subscription" do
    post :create, :user_name => "ttaylor", :password => "testing"
    assert_redirected_to subscription_url(subscriptions(:tim))
    assert_equal users(:tim).id, @response.session[:user_id]
  end

  test "create should redirect to subscription index on success when multiple subscriptions" do
    post :create, :user_name => "jjohnson", :password => "testing"
    assert_redirected_to subscriptions_url
    assert_equal users(:john).id, @response.session[:user_id]
  end

  test "destroy should remove user_id from session" do
    login! :john

    get :destroy
    assert_redirected_to new_session_url
    assert @response.session[:user_id].blank?
  end
end
