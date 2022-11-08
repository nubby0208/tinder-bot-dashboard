class AddIdentityVerificationToTinderAccount < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      ALTER TYPE swipe_job_status ADD VALUE 'identity_verification';
    SQL
    execute <<-SQL
      ALTER TYPE tinder_account_status ADD VALUE 'identity_verification';
    SQL
  end
end
