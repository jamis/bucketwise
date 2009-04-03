require 'test_helper'

class BucketsControllerTest < ActionController::TestCase
  setup :login_default_user

  test "index should 404 when when user without permissions requests page" do
    get :index, :account_id => accounts(:tim_checking).id
    assert_response :missing
  end

  test "show should 404 when when user without permissions requests page" do
    get :show, :id => buckets(:tim_checking_general).id
    assert_response :missing
  end

  test "update should 404 when user without permissions requests page" do
    xhr :put, :update, :id => buckets(:tim_checking_general).id, :bucket => { :name => "Hi!" }
    assert_response :missing
    assert_equal "General", buckets(:tim_checking_general, :reload).name
  end

  test "index should load account and subscription and render page" do
    get :index, :account_id => accounts(:john_checking).id
    assert_response :success
    assert_template "buckets/index"
    assert_equal subscriptions(:john), assigns(:subscription)
    assert_equal accounts(:john_checking), assigns(:account)
  end

  test "show should load bucket, account, and subscription and render page" do
    get :show, :id => buckets(:john_checking_dining).id
    assert_response :success
    assert_template "buckets/show"
    assert_equal subscriptions(:john), assigns(:subscription)
    assert_equal accounts(:john_checking), assigns(:account)
    assert_equal buckets(:john_checking_dining), assigns(:bucket)
  end

  test "update should change bucket name and render javascript" do
    xhr :put, :update, :id => buckets(:john_checking_general).id, :bucket => { :name => "Hi!" }
    assert_response :success
    assert_template "buckets/update.js.rjs"
    assert_equal subscriptions(:john), assigns(:subscription)
    assert_equal accounts(:john_checking), assigns(:account)
    assert_equal buckets(:john_checking_general), assigns(:bucket)
    assert_equal "Hi!", buckets(:john_checking_general, :reload).name
  end

  test "destroy without receiver_id should 404" do
    assert_no_difference "Bucket.count" do
      delete :destroy, :id => buckets(:john_checking_dining).id
    end
    assert_response :missing
  end

  test "destroy should assimilate line items and destroy bucket" do
    assert_difference "Bucket.count", -1 do
      delete :destroy, :id => buckets(:john_checking_dining).id,
        :receiver_id => buckets(:john_checking_groceries).id
    end
    assert_redirected_to(buckets(:john_checking_groceries))
    assert !Bucket.exists?(buckets(:john_checking_dining).id)
    assert buckets(:john_checking_groceries), line_items(:john_lunch_checking_dining).bucket
  end
end
