require 'test_helper'

class EventsControllerTest < ActionController::TestCase
  setup :login_default_user

  test "show should 404 when user without permissions requests page" do
    xhr :get, :show, :id => events(:tim_checking_starting_balance).id
    assert_response :missing
  end

  test "edit should 404 when user without permissions requests page" do
    get :edit, :id => events(:tim_checking_starting_balance).id
    assert_response :missing
  end

  test "create should 404 when user without permissions requests page" do
    assert_no_difference "Event.count" do
      xhr :post, :create, :subscription_id => subscriptions(:tim).id,
        :event => simple_event(:tim_checking, :tim_checking_general)
      assert_response :missing
    end
  end

  test "update should 404 when user without permissions requests page" do
    xhr :post, :update, :id => events(:tim_checking_starting_balance).id
    assert_response :missing
  end

  test "destroy should 404 when user without permissions requests page" do
    assert_no_difference "Event.count" do
      xhr :delete, :destroy, :id => events(:tim_checking_starting_balance).id
      assert_response :missing
    end
  end

  test "show via ajax should load subscription and event and render javascript" do
    xhr :get, :show, :id => events(:john_lunch).id
    assert_response :success
    assert_template "events/show.js.rjs"
    assert_equal subscriptions(:john), assigns(:subscription)
    assert_equal events(:john_lunch), assigns(:event)
  end

  test "edit should load subscription and event and render page" do
    get :edit, :id => events(:john_lunch).id
    assert_response :success
    assert_template "events/edit"
    assert_equal subscriptions(:john), assigns(:subscription)
    assert_equal events(:john_lunch), assigns(:event)
  end

  test "create via ajax should load subscription and create event and render javascript" do
    assert_difference "subscriptions(:john).events.count" do
      xhr :post, :create, :subscription_id => subscriptions(:john).id,
        :event => simple_event(:john_checking, :john_checking_household)
      assert_response :success
    end

    assert_template "events/create.js.rjs"
    assert_equal subscriptions(:john), assigns(:subscription)
    assert_equal "Somebody", assigns(:event).actor
  end

  test "update via ajax should load subscription and event, update event and render javascript" do
    event = events(:john_checking_starting_balance)
    xhr :post, :update, :id => event.id,
      :event => { :occurred_on => event.occurred_on.to_s, :actor => "Updated: #{event.actor}" }

    assert_response :success
    assert_template "events/update.js.rjs"
    assert_equal subscriptions(:john), assigns(:subscription)
    assert_equal events(:john_checking_starting_balance), assigns(:event)
    assert events(:john_checking_starting_balance, :reload).actor.starts_with?("Updated: ")
  end

  test "destroy via ajax should load subscription and event, destroy event and render javascript" do
    assert_difference "subscriptions(:john).events.count", -1 do
      xhr :delete, :destroy, :id => events(:john_lunch).id
      assert_response :success
    end

    assert_template "events/destroy.js.rjs"
    assert_equal subscriptions(:john), assigns(:subscription)
    assert_equal events(:john_lunch), assigns(:event)
    assert !Event.exists?(events(:john_lunch).id)
  end

  test "new should 404 when user without permission requests page" do
    get :new, :subscription_id => subscriptions(:tim).id
    assert_response :missing
  end

  test "new should 404 when user requests from bucket without access" do
    get :new, :subscription_id => subscriptions(:john).id, :role => :reallocation, :from => buckets(:tim_checking_general).id
    assert_response :missing
  end

  test "new should 404 when user requests to bucket without access" do
    get :new, :subscription_id => subscriptions(:john).id, :role => :reallocation, :to => buckets(:tim_checking_general).id
    assert_response :missing
  end

  test "new 'from reallocation' should render correct edit form" do
    get :new, :subscription_id => subscriptions(:john).id, :role => :reallocation, :from => buckets(:john_checking_general).id
    assert_response :success
    assert_template "events/new"
    assert_select "#reallocate_from"
    assert_select "#reallocate_to", false
  end

  test "new 'to reallocation' should render correct edit form" do
    get :new, :subscription_id => subscriptions(:john).id, :role => :reallocation, :to => buckets(:john_checking_general).id
    assert_response :success
    assert_template "events/new"
    assert_select "#reallocate_to"
    assert_select "#reallocate_from", false
  end

  private

    def simple_event(account, bucket)
      { :occurred_on => Date.today.to_s, :actor => "Somebody",
        :line_items => [
          { :account_id => accounts(account).id.to_s,
            :bucket_id  => buckets(bucket).id.to_s,
            :amount     => "-2000",
            :role       => "payment_source" }
          ],
          :tagged_items => [] }
    end
end
