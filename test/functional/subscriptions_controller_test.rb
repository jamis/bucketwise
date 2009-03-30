require 'test_helper'

class SubscriptionsControllerTest < ActionController::TestCase
  setup :login_as_john

  test "index should redirect to sole subscription if there is only one" do
    login! :tim
    get :index
    assert_redirected_to subscription_url(subscriptions(:tim))
  end

  test "index should list all subscriptions if there are many" do
    get :index
    assert_response :success
    assert_template "subscriptions/index"
  end

  test "index should not include any subscriptions not accessible to user" do
    get :index
    assert_response :success
    assert_select "li#subscription_#{subscriptions(:john).id}"
    assert_select "li#subscription_#{subscriptions(:john_family).id}"
    assert_select "li#subscription_#{subscriptions(:tim).id}", false
  end

  test "show should 404 for invalid subscription" do
    assert !Subscription.exists?(1)
    get :show, :id => 1
    assert_response :missing
  end

  test "show should 404 for inaccessible subscription" do
    get :show, :id => subscriptions(:tim).id
    assert_response :missing
  end

  test "show should display dashboard for selected subscription" do
    get :show, :id => subscriptions(:john).id
    assert_response :success
    assert_template "subscriptions/show"
    assert_equal subscriptions(:john), assigns(:subscription)
  end

  protected

    def login_as_john
      login! :john
    end
end
