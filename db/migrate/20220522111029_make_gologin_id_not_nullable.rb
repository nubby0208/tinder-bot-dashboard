class MakeGologinIdNotNullable < ActiveRecord::Migration[7.0]
  def change
    change_column_null :tinder_accounts, :gologin_profile_id, false
  end
end
