require 'test_helper'

class TagsControllerTest < ActionController::TestCase
  setup :login_default_user

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

  # == API tests ========================================================================

  test "index via API for inaccessible subscription should 404" do
    get :index, :subscription_id => subscriptions(:tim).id, :format => "xml"
    assert_response :missing
  end

  test "index via API should return list of all tags for given subscription" do
    get :index, :subscription_id => subscriptions(:john).id, :format => "xml"
    assert_response :success
    xml = Hash.from_xml(@response.body)
    assert xml.key?("tags")
  end

  test "show via API should return record for the given tag" do
    get :show, :id => tags(:john_tip).id, :format => "xml"
    assert_response :success
    xml = Hash.from_xml(@response.body)
    assert_equal tags(:john_tip).id, xml["tag"]["id"]
  end

  test "new via API should return template record" do
    get :new, :subscription_id => subscriptions(:john).id, :format => "xml"
    assert_response :success
    xml = Hash.from_xml(@response.body)
    assert xml.key?("tag")
  end

  test "create via API for inaccessible subscription should 404" do
    assert_no_difference "Tag.count" do
      post :create, :subscription_id => subscriptions(:tim).id, :format => "xml",
        :tag => { :name => "testing" }
      assert_response :missing
    end
  end

  test "create via API should return 201 and set location header" do
    assert_difference "Tag.count" do
      post :create, :subscription_id => subscriptions(:john).id, :format => "xml",
        :tag => { :name => "testing" }
      assert_response :success
      assert @response.headers['Location']
      xml = Hash.from_xml(@response.body)
      assert xml.key?("tag")
    end
  end

  test "create via API should return 422 with errors if validations fail" do
    assert_no_difference "Tag.count" do
      post :create, :subscription_id => subscriptions(:john).id, :format => "xml",
        :tag => { :name => "tip" }
      assert_response :unprocessable_entity
      xml = Hash.from_xml(@response.body)
      assert xml.key?("errors")
    end
  end

  test "update via API for inaccessible tag should 404" do
    put :update, :id => tags(:tim_milk).id, :tag => { :name => "milkshake" }, :format => "xml"
    assert_response :missing
    assert_equal "milk", tags(:tim_milk, :reload).name
  end

  test "update via API should change tag name and return 200" do
    put :update, :id => tags(:john_tip).id, :tag => { :name => "gratuity" }, :format => "xml"
    assert_response :success
    xml = Hash.from_xml(@response.body)
    assert xml.key?("tag")
    assert_equal "gratuity", tags(:john_tip, :reload).name
  end

  test "update via API should return 422 with errors if validations fail" do
    put :update, :id => tags(:john_tip).id, :tag => { :name => "lunch" }, :format => "xml"
    assert_response :unprocessable_entity
    xml = Hash.from_xml(@response.body)
    assert xml.key?("errors")
    assert_equal "tip", tags(:john_tip, :reload).name
  end

  test "destroy via API should remove tag and return 200" do
    assert_difference "Tag.count", -1 do
      delete :destroy, :id => tags(:john_tip).id, :format => "xml"
      assert_response :success
    end
  end
end
