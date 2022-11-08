class TinderSwipe < ApplicationRecord
  # belongs_to :tinder_account
  belongs_to :swipe_job
  validates :swipe_job, presence: true
end
