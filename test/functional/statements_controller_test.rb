require 'test_helper'

class StatementsControllerTest < ActionController::TestCase
  setup :login_default_user

  test "index for inaccessible account should 404" do
    get :index, params: { :account_id => accounts(:tim_checking).id }
    assert_response :missing
  end

  test "index should list only balanced statements" do
    get :index, params: { :account_id => accounts(:john_checking).id }
    assert_response :success
    assert_template "statements/index"
    assert_equal [statements(:john)], assigns(:statements)
  end

  test "new for inaccessible account should 404" do
    get :new, params: { :account_id => accounts(:tim_checking).id }
    assert_response :missing
  end

  test "new should build template record and render" do
    get :new, params: { :account_id => accounts(:john_checking).id }
    assert_response :success
    assert_template "statements/new"
    assert assigns(:statement).new_record?
  end

  test "create for inaccessible account should 404" do
    assert_no_difference "Statement.count" do
      post :create, params: { :account_id => accounts(:tim_checking).id,
        :statement => { :occurred_on => Date.today, :ending_balance => 1234_56 } }
      assert_response :missing
    end
  end

  test "create should create new record and redirect to edit" do
    assert_difference "accounts(:john_checking, :reload).statements.size" do
      post :create, params: { :account_id => accounts(:john_checking).id,
        :statement => { :occurred_on => Date.today, :ending_balance => 1234_56 } }
      assert_redirected_to edit_statement_url(assigns(:statement))
    end
  end

  test "show for inaccessible statement should 404" do
    get :show, params: { :id => statements(:tim).id }
    assert_response :missing
  end

  test "show should load statement record and render" do
    get :show, params: { :id => statements(:john).id }
    assert_response :success
    assert_template "statements/show"
    assert_equal statements(:john), assigns(:statement)
  end

  test "edit for inaccessible statement should 404" do
    get :edit, params: { :id => statements(:tim).id }
    assert_response :missing
  end

  test "edit should load statement record and render" do
    get :edit, params: { :id => statements(:john).id }
    assert_response :success
    assert_template "statements/edit"
    assert_equal statements(:john), assigns(:statement)
  end

  test "update for inaccessible statement should 404" do
    put :update, params: { :id => statements(:tim).id,
      :statement => { :occurred_on => statements(:tim).occurred_on,
        :ending_balance => statements(:tim).ending_balance,
        :cleared => [account_items(:tim_checking_starting_balance).id] } }
    assert_response :missing
    assert statements(:tim, :reload).account_items.empty?
  end

  test "update should load statement and update statement and redirect" do
    statement = statements(:john_pending)
    assert statements(:john_pending).account_items.empty?
    put :update, params: { :id => statements(:john_pending).id,
      :statement => { :occurred_on => statements(:john_pending).occurred_on,
        :ending_balance => statements(:john_pending).ending_balance,
        :cleared => [account_items(:john_lunch_again_checking).id] } }
    assert_redirected_to account_url(statements(:john_pending).account)
    assert_equal [account_items(:john_lunch_again_checking)],
      statements(:john_pending, :reload).account_items
  end

  test "destroy for inaccessible statement should 404" do
    assert_no_difference "Statement.count" do
      delete :destroy, params: { :id => statements(:tim).id }
      assert_response :missing
    end
  end

  test "destroy should load and destroy statement and redirect" do
    delete :destroy, params: { :id => statements(:john).id }
    assert_redirected_to account_url(statements(:john).account)
    assert !Statement.exists?(statements(:john).id)
  end
end
