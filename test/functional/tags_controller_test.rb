require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  setup :login_as_john

  test "show should 404 for invalid tag" do
    assert !Tag.exists?(1)
    get :show, :id => 1
    assert_response :missing
  end

  test "show should 404 for inaccessible tag" do
    get :show, :id => tags(:tim_milk).id
    assert_response :missing
  end

  test "show should display tag perma page for requested tag" do
    get :show, :id => tags(:john_lunch).id
    assert_response :success
    assert_template "tags/show"
    assert_equal tags(:john_lunch), assigns(:tag_ref)
  end

  test "update should 404 for inaccessible tag" do
    xhr :put, :update, :id => tags(:tim_milk).id, :tag => { :name => "hijacked!" }
    assert_response :missing
    assert_equal "milk", tags(:tim_milk, :reload).name
  end

  test "update should change tag name and render javascript response" do
    xhr :put, :update, :id =>tags(:john_lunch).id, :tag => { :name => "hijacked!" }
    assert_response :success
    assert_template "tags/update.js.rjs"
    assert_equal "hijacked!", tags(:john_lunch, :reload).name
  end

  protected

    def login_as_john
      login! :john
    end
end
