class DropUniqueIndexSwipeJobs < ActiveRecord::Migration[7.0]
  def change
    remove_index :swipe_jobs, name: :swipe_jobs_status_tinder_account_id_idx
  end
end
