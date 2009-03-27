require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "authenticate should return user if password is correct" do
    assert_equal users(:john), User.authenticate("jjohnson", "testing")
  end

  test "authenticate should return nil if user_name is incorrect" do
    assert_nil User.authenticate("john", "testing")
  end

  test "authenticate should return nil if password is incorrect" do
    assert_nil User.authenticate("jjohnson", "test")
  end

  test "creating new user should set salt and hash password" do
    user = subscriptions(:john).users.create(:name => "Tom Thompson",
      :email => "tthompson@domain.test", :user_name => "tthompson",
      :password => "thePassword")
    assert !user.password_hash.blank?
    assert !user.salt.blank?
    assert_equal user, User.authenticate("tthompson", "thePassword")
  end

  test "updating user's password should change salt and hash new password" do
    old_salt = users(:john).salt
    old_password_hash = users(:john).password_hash

    users(:john).update_attribute :password, "vamoose!"
    assert_not_equal users(:john).salt, old_salt
    assert_not_equal users(:john).password_hash, old_password_hash

    assert_nil User.authenticate("jjohnson", "testing")
    assert_equal users(:john), User.authenticate("jjohnson", "vamoose!")
  end

  test "creating new user with duplicate user name should fail" do
    begin
      subscriptions(:john).users.create(:name => "James Johnson",
        :email => "james.johnson@domain.test", :user_name => "jjohnson",
        :password => "ponies!")
    rescue ActiveRecord::RecordInvalid => error
      assert error.record.errors.on(:user_name)
    else
      flunk "expected create to fail"
    end
  end
end
