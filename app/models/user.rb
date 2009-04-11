require 'digest/sha1'

class User < ActiveRecord::Base
  has_many :user_subscriptions
  has_many :subscriptions, :through => :user_subscriptions

  attr_accessible :name, :email, :user_name, :password

  attr_writer :password

  before_save :set_password_hash_and_salt

  validates_uniqueness_of :user_name

  def self.password_hash_for(password, salt)
    Digest::SHA1.hexdigest(salt + password)
  end

  def self.authenticate(user_name, password)
    user = find_by_user_name(user_name) or return nil
    hash = password_hash_for(password, user.salt)
    hash == user.password_hash ? user : nil
  end

  protected

    def set_password_hash_and_salt
      if @password
        self.salt = Array.new(32) { 32 + rand(95) }.pack("C*")
        self.password_hash = self.class.password_hash_for(@password, salt)
        @password = nil
      end
    end
end
