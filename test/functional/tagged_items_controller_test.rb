require 'test_helper'

class TaggedItemsControllerTest < ActionController::TestCase
  setup :login_default_user

  # == API tests ========================================================================

  test "create via API for inaccessible event should 404" do
    assert_no_difference "TaggedItem.count" do
      post :create, params: { :event_id => events(:tim_checking_starting_balance).id,
        :tagged_item => { :amount => 100, :tag_id => tags(:john_tip).id } },
        :format => "xml"
      assert_response :missing
    end
  end

  test "create via API for inaccessible tag should 404" do
    assert_no_difference "TaggedItem.count" do
      post :create, params: { :event_id => events(:john_lunch).id,
        :tagged_item => { :amount => 100, :tag_id => tags(:tim_milk).id } },
        :format => "xml"
      assert_response :missing
    end
  end

  test "create via API should add tagged item and return 201" do
    assert_difference "TaggedItem.count" do
      post :create, params: { :event_id => events(:john_lunch).id,
        :tagged_item => { :amount => 100, :tag_id => tags(:john_fuel).id } },
        :format => "xml"
      assert_response :success
    end

    xml = Hash.from_xml(@response.body)
    assert xml.key?("tagged_item")
    assert events(:john_lunch, :reload).tagged_items.any? { |i| i.tag == tags(:john_fuel) }
  end

  test "create via API should allow tag to be specified by name" do
    assert_difference "TaggedItem.count" do
      assert_difference "Tag.count" do
        post :create, params: { :event_id => events(:john_lunch).id,
          :tagged_item => { :amount => 100, :tag_id => "n:misc" } },
          :format => "xml"
        assert_response :success
      end
    end

      xml = Hash.from_xml(@response.body)
      assert xml.key?("tagged_item")
      assert events(:john_lunch, :reload).tagged_items.any? { |i| i.tag.name == "misc" }
  end

  test "destroy via API for inaccessible tagged item should 404" do
    login! :tim
    assert_no_difference "TaggedItem.count" do
      delete :destroy, params: { :id => tagged_items(:john_lunch_tip).id }, :format => "xml"
      assert_response :missing
    end
  end

  test "destroy via API should remove tagged item from event and return 200" do
    assert_difference "TaggedItem.count", -1 do
      delete :destroy, params: { :id => tagged_items(:john_lunch_tip).id }, :format => "xml"
      assert_response :success
    end
  end
end
