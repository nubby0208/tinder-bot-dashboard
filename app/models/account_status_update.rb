class AccountStatusUpdate < ApplicationRecord
  belongs_to :tinder_account
  belongs_to :swipe_job
  has_one :user, through: :tinder_account
  enum status: TinderAccount.statuses, _prefix: 'after'
  enum before_status: TinderAccount.statuses, _prefix: 'before'
end
