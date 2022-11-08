class SwapReferencesPort < ActiveRecord::Migration[7.0]
  def change
    add_reference :ports, :swipe_job, foreign_key: true, index: { unique: true }
    remove_reference :swipe_jobs, :port, foreign_key: true, index: { unique: true }
  end
end
