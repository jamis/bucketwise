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
    xhr :put, :update, :id => tags(:john_lunch).id, :tag => { :name => "hijacked!" }
    assert_response :success
    assert_template "tags/update.js.rjs"
    assert_equal "hijacked!", tags(:john_lunch, :reload).name
  end

  test "destroy should 404 for inaccessible tag" do
    assert_no_difference "Tag.count" do
      assert_no_difference "TaggedItem.count" do
        delete :destroy, :id => tags(:tim_milk).id
        assert_response :missing
      end
    end
  end

  test "destroy should remove tag and all associated tagged items" do
    item = tagged_items(:john_lunch_lunch)

    delete :destroy, :id => tags(:john_lunch).id
    assert_redirected_to subscription_url(subscriptions(:john))

    assert !Tag.exists?(tags(:john_lunch).id)
    assert !TaggedItem.exists?(item.id)
  end

  test "merge should 404 when target tag is inaccessible" do
    assert_no_difference "Tag.count" do
      assert_no_difference "TaggedItem.count" do
        delete :destroy, :id => tags(:john_lunch).id, :receiver_id => tags(:tim_milk).id
        assert_response :missing
      end
    end
  end

  test "merge should 422 when target tag is same as deleted tag" do
    assert_no_difference "Tag.count" do
      assert_no_difference "TaggedItem.count" do
        delete :destroy, :id => tags(:john_lunch).id, :receiver_id => tags(:john_lunch).id
        assert_response :unprocessable_entity
      end
    end
  end

  test "merge should remove tag and move all associated tagged items to target tag" do
    balance = tags(:john_fuel).balance

    delete :destroy, :id => tags(:john_lunch).id, :receiver_id => tags(:john_fuel).id
    assert_redirected_to(tag_url(tags(:john_fuel)))

    assert !Tag.exists?(tags(:john_lunch).id)
    assert_equal tags(:john_fuel), tagged_items(:john_lunch_lunch).tag
    assert_equal balance + tagged_items(:john_lunch_lunch).amount, tags(:john_fuel, :reload).balance
  end

  protected

    def login_as_john
      login! :john
    end
end
