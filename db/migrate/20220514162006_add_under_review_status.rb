class AddUnderReviewStatus < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      ALTER TYPE tinder_account_status ADD VALUE 'under_review';
    SQL
  end
end
