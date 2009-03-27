require 'test_helper'

class AccountsControllerTest < ActionController::TestCase
  setup :login_default_user

  test "show should 404 when when user without permissions requests page" do
    get :show, :id => accounts(:tim_checking).id
    assert_response :missing
  end

  test "create should 404 when when user without permissions requests page" do
    assert_no_difference "Account.count" do
      post :create, {
        :subscription_id => subscriptions(:tim).id,
        :account => { :name => "Savings", :role => "saving" } }
      assert_response :missing
    end
  end

  test "show should load account and subscription and render page" do
    get :show, :id => accounts(:john_checking).id
    assert_response :success
    assert_template "accounts/show"
    assert_equal accounts(:john_checking), assigns(:account)
    assert_equal subscriptions(:john), assigns(:subscription)
  end

  test "create should load subscription and create account and redirect" do
    assert_difference "subscriptions(:john).accounts.count" do
      post :create, {
        :subscription_id => subscriptions(:john).id,
        :account => { :name => "Mortgage", :role => "" } }
      assert_redirected_to(subscription_url(subscriptions(:john)))
    end

    assert_equal subscriptions(:john), assigns(:subscription)
    assert assigns(:account)
  end
end
