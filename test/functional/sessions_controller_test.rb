require 'test_helper'

class SessionsControllerTest < ActionController::TestCase
  test "new should render login page" do
    get :new
    assert_response :success
    assert_template "sessions/new"
  end

  test "create should redirect to login page on bad user name" do
    post :create, params: { :user_name => "jimjim", :password => "whatever" }
    assert_redirected_to new_session_url
  end

  test "create should redirect to login page on bad password" do
    post :create, params: { :user_name => "john", :password => "whatever" }
    assert_redirected_to new_session_url
  end

  test "create should redirect to subscription page on success when only one subscription" do
    post :create, params: { :user_name => "ttaylor", :password => "testing" }
    assert_redirected_to subscription_url(subscriptions(:tim))
  end

  test "create should redirect to subscription index on success when multiple subscriptions" do
    post :create, params: { :user_name => "jjohnson", :password => "testing" }
    assert_redirected_to subscriptions_url
  end

  test "destroy should remove user_id from session" do
    login! :john

    get :destroy
    assert_redirected_to new_session_url
  end
end
