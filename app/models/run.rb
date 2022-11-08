class Run < ApplicationRecord
  belongs_to :swipe_job
  enum result: TinderAccount.statuses
  has_one :user, through: :swipe_job
  has_one :tinder_account, through: :swipe_job

  # scope :not_status_check, -> { where.not(job_type: 'status_check') }
  # scope :status_check, -> { where(job_type: 'status_check') }
  scope :running, -> { where(status: 'running') }
  scope :failed, -> { where(status: 'failed') }
  scope :completed, -> { where(status: 'completed') }
  scope :past24h, -> { where("created_at > ?", 1.day.ago) }
end

