class FanModel < ApplicationRecord
  belongs_to :user
  has_many :tinder_accounts
  validates :name, uniqueness: { scope: :user_id }, presence: true

  def accounts
    tinder_accounts.count
  end

  def active
    tinder_accounts.active.count
  end

  def banned
    tinder_accounts.banned.count
  end

  def captcha
    tinder_accounts.captcha.count
  end

  def logged_out
    tinder_accounts.logged_out.count
  end

  def shadowbanned
    tinder_accounts.shadowbanned.count
  end

  def proxy_error
    tinder_accounts.proxy_error.count
  end

  def under_review
    tinder_accounts.under_review.count
  end
end
