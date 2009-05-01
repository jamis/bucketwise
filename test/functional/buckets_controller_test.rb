require 'test_helper'

class BucketsControllerTest < ActionController::TestCase
  setup :login_default_user

  test "index should 404 when when user without permissions requests page" do
    get :index, :account_id => accounts(:tim_checking).id
    assert_response :missing
  end

  test "index should load account and subscription and render page" do
    get :index, :account_id => accounts(:john_checking).id
    assert_response :success
    assert_template "buckets/index"
    assert_equal subscriptions(:john), assigns(:subscription)
    assert_equal accounts(:john_checking), assigns(:account)
    assert_equal accounts(:john_checking).buckets.length, assigns(:buckets).length
    assert !assigns(:filter).any?
  end

  test "index with filter options should set filter and return only matching buckets" do
    get :index, :account_id => accounts(:john_checking).id, :expenses => true
    assert_response :success
    assert_template "buckets/index"
    assert assigns(:filter).any?
    assert_equal %w(Aside Dining), assigns(:buckets).map(&:name).sort
  end

  test "show should 404 when when user without permissions requests page" do
    get :show, :id => buckets(:tim_checking_general).id
    assert_response :missing
  end

  test "show should load bucket, account, and subscription and render page" do
    get :show, :id => buckets(:john_checking_dining).id
    assert_response :success
    assert_template "buckets/show"
    assert_equal subscriptions(:john), assigns(:subscription)
    assert_equal accounts(:john_checking), assigns(:account)
    assert_equal buckets(:john_checking_dining), assigns(:bucket)
  end

  test "update should 404 when user without permissions requests page" do
    xhr :put, :update, :id => buckets(:tim_checking_general).id, :bucket => { :name => "Hi!" }
    assert_response :missing
    assert_equal "General", buckets(:tim_checking_general, :reload).name
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

  # == API tests ========================================================================

  test "index via API should return bucket list for account" do
    get :index, :account_id => accounts(:john_checking).id, :format => "xml"
    assert_response :success
    xml = Hash.from_xml(@response.body)
    assert_equal accounts(:john_checking).buckets.length, xml["buckets"].length
  end

  test "show via API should return bucket record" do
    get :show, :id => buckets(:john_checking_dining).id, :format => "xml"
    assert_response :success
    xml = Hash.from_xml(@response.body)
    assert_equal buckets(:john_checking_dining).id, xml["bucket"]["id"]
  end

  test "new via API should return a template XML response" do
    get :new, :account_id => accounts(:john_checking).id, :format => "xml"
    assert_response :success
    xml = Hash.from_xml(@response.body)
    assert xml["bucket"]
    assert !xml["bucket"]["id"]
  end

  test "create via API should return 422 with error messages when validations fail" do
    post :create,
      :account_id => accounts(:john_checking).id,
      :bucket => { :name => "Dining", :role => "" },
      :format => "xml"
    assert_response :unprocessable_entity
    xml = Hash.from_xml(@response.body)
    assert xml["errors"].any?
  end

  test "create via API should create record and respond with 201" do
    assert_difference "accounts(:john_checking).buckets.count" do
      post :create,
        :account_id => accounts(:john_checking).id,
        :bucket => { :name => "Utilities", :role => "" },
        :format => "xml"
      assert_response :created
      assert @response.headers["Location"]
    end
  end

  test "update via API should update record and respond with 200" do
    put :update, :id => buckets(:john_checking_dining).id, :bucket => { :name => "Hi!" }, :format => "xml"
    assert_response :success
    xml = Hash.from_xml(@response.body)
    assert_equal "Hi!", xml["bucket"]["name"]
  end

  test "update via API with validation errors should respond with 422" do
    put :update, :id => buckets(:john_checking_dining).id, :bucket => { :name => "Groceries" }, :format => "xml"
    assert_response :unprocessable_entity
    xml = Hash.from_xml(@response.body)
    assert xml["errors"].any?
  end

  test "destroy via API should remove record and respond with 200" do
    assert_difference "Bucket.count", -1 do
      delete :destroy, :id => buckets(:john_checking_dining).id,
        :receiver_id => buckets(:john_checking_groceries).id,
        :format => "xml"
      assert_response :success
    end
  end
end
