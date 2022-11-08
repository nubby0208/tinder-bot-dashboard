class CreateTinderAccounts < ActiveRecord::Migration[7.0]
  def change
    # create_table :of_models do |t|
    #   t.string :full_name
    #   t.timestamps
    # end

    execute <<-SQL
      CREATE TYPE tinder_account_status AS ENUM
      ('banned', 'shadowbanned', 'verification_required', 'active');
    SQL

    create_table :tinder_accounts do |t|
      t.column :status, :tinder_account_status, null: false, default: :active
      # t.string :profile_name, null: false
      # t.datetime :created_date, null: false
      t.boolean :active, null: false, default: true
      t.datetime :shadowban_detected_at
      t.integer :right_swipes, null: false, default: 0
      t.integer :left_swipes, null: false, default: 0
      t.integer :swipes_past24h, :integer, null: false, default: 0
      t.integer :swipes_per_day_goal
      t.integer :total_swipes, null: false, default: 0
      t.string :gologin_profile_id, null: false
      t.string :gologin_profile_name, null: false
      t.string :gologin_folder
      # t.references :of_models, foreign_key: true
      # t.references :phone_number, null: false
      # t.references :google_account, null: false
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end


    execute <<-SQL
      CREATE TYPE swipe_job_status AS ENUM
      ('pending', 'running', 'completed', 'failed');
    SQL

    create_table :swipe_jobs do |t|
      t.references :tinder_account, null: false, foreign_key: true
      t.column :status, :swipe_job_status, null: false, default: :pending
      t.integer :target, default: 0, null: false
      t.integer :swipes, null: false, default: 0
      t.datetime :started_at
      t.datetime :failed_at
      t.text :failed_reason
      t.datetime :completed_at
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end

    create_table :tinder_swipes do |t|
      t.boolean :right_swipe, null: false
      t.references :swipe_job, null: false, foreign_key: true
      t.timestamps
    end

    execute <<-SQL
      create unique index on swipe_jobs(status, tinder_account_id)
      where status in ('pending', 'running');
    SQL
  end
end
