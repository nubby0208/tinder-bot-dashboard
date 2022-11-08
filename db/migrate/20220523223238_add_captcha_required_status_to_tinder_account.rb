class AddCaptchaRequiredStatusToTinderAccount < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
      ALTER TYPE tinder_account_status ADD VALUE 'captcha_required';
    SQL
  end
end
