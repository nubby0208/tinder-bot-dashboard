# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2022_11_01_055106) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "adminpack"
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "swipe_job_repeat_unit", ["daily", "hourly"]
  create_enum "swipe_job_status", ["pending", "running", "completed", "failed", "queued", "cancelled", "ran_out_of_likes", "identity_verification", "scheduled", "ran_limit_of_likes"]
  create_enum "swipe_job_type", ["likes", "recommended", "status_check", "location_change", "limit_of_likes"]
  create_enum "tinder_account_status", ["banned", "shadowbanned", "verification_required", "active", "under_review", "logged_out", "captcha_required", "identity_verification", "profile_deleted", "proxy_error", "out_of_likes", "age_restricted", "", "limit_of_likes"]

  create_table "account_status_updates", force: :cascade do |t|
    t.enum "status", null: false, enum_type: "tinder_account_status"
    t.bigint "tinder_account_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "swipe_job_id"
    t.enum "before_status", enum_type: "tinder_account_status"
    t.integer "retry"
    t.index ["swipe_job_id"], name: "index_account_status_updates_on_swipe_job_id"
    t.index ["tinder_account_id"], name: "index_account_status_updates_on_tinder_account_id"
  end

  create_table "fan_models", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "user_id"], name: "index_fan_models_on_name_and_user_id", unique: true
    t.index ["user_id"], name: "index_fan_models_on_user_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "population"
    t.bigint "user_id"
    t.index ["name"], name: "index_locations_on_name", unique: true
    t.index ["user_id"], name: "index_locations_on_user_id"
  end

  create_table "matches", force: :cascade do |t|
    t.bigint "tinder_account_id"
    t.string "tinder_user_id", null: false
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tinder_account_id", "tinder_user_id"], name: "index_matches_on_tinder_account_id_and_tinder_user_id", unique: true
    t.index ["tinder_account_id"], name: "index_matches_on_tinder_account_id"
    t.index ["tinder_user_id"], name: "index_matches_on_tinder_user_id"
  end

  create_table "runs", force: :cascade do |t|
    t.bigint "swipe_job_id", null: false
    t.enum "status", default: "running", null: false, enum_type: "swipe_job_status"
    t.integer "swipes", default: 0, null: false
    t.enum "result", enum_type: "tinder_account_status"
    t.text "failed_reason"
    t.datetime "failed_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["swipe_job_id"], name: "index_runs_on_swipe_job_id"
  end

  create_table "schedules", force: :cascade do |t|
    t.integer "swipes_per_day_max"
    t.time "start_time"
    t.time "stop_time"
    t.integer "split_jobs", default: 1
    t.enum "job_type", default: "likes", null: false, enum_type: "swipe_job_type"
    t.decimal "recommended_percentage", default: "80.0", null: false
    t.decimal "delay", default: "1000.0", null: false
    t.decimal "delay_variance", default: "30.0", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "swipes_per_day_increment_max", default: 0
    t.integer "swipes_per_day_increment", default: 0
    t.integer "swipes_per_day_min"
    t.datetime "run_at"
    t.boolean "run_now", default: false, null: false
    t.integer "recurring", default: 24
    t.index ["user_id"], name: "index_schedules_on_user_id"
  end

  create_table "swipe_jobs", force: :cascade do |t|
    t.bigint "tinder_account_id", null: false
    t.enum "status", default: "pending", null: false, enum_type: "swipe_job_status"
    t.integer "target", default: 0, null: false
    t.integer "swipes", default: 0, null: false
    t.datetime "started_at"
    t.datetime "failed_at"
    t.text "failed_reason"
    t.datetime "completed_at"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.enum "job_type", default: "likes", null: false, enum_type: "swipe_job_type"
    t.integer "delay", default: 1000
    t.integer "retries", default: 0, null: false
    t.decimal "recommended_percentage", default: "80.0", null: false
    t.datetime "last_swiped"
    t.datetime "swiped_at"
    t.decimal "delay_variance", default: "30.0"
    t.datetime "scheduled_at"
    t.integer "repeat_n"
    t.enum "repeat_unit", enum_type: "swipe_job_repeat_unit"
    t.string "created_by"
    t.bigint "schedule_id"
    t.enum "account_job_status_result", enum_type: "tinder_account_status"
    t.boolean "warm_up", default: false, null: false
    t.boolean "gold", default: true
    t.index ["schedule_id"], name: "index_swipe_jobs_on_schedule_id"
    t.index ["tinder_account_id"], name: "index_swipe_jobs_on_tinder_account_id"
    t.index ["user_id"], name: "index_swipe_jobs_on_user_id"
    t.check_constraint "repeat_unit IS NULL AND repeat_n IS NULL OR repeat_unit IS NOT NULL AND repeat_n IS NOT NULL", name: "repeat"
  end

  create_table "tinder_accounts", force: :cascade do |t|
    t.enum "status", default: "active", null: false, enum_type: "tinder_account_status"
    t.boolean "active", default: true, null: false
    t.datetime "shadowban_detected_at"
    t.integer "right_swipes", default: 0, null: false
    t.integer "left_swipes", default: 0, null: false
    t.integer "swipes_past24h", default: 0, null: false
    t.integer "integer", default: 0, null: false
    t.integer "swipes_per_day_goal"
    t.integer "total_swipes", default: 0, null: false
    t.string "gologin_profile_id", null: false
    t.string "gologin_profile_name"
    t.string "gologin_folder"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "number"
    t.string "email"
    t.string "acc_pass"
    t.boolean "gold", default: false, null: false
    t.boolean "verified", default: false, null: false
    t.bigint "location_id"
    t.bigint "fan_model_id"
    t.date "created_date"
    t.string "proxy_ip"
    t.string "proxy_country"
    t.string "proxy_city"
    t.string "proxy_region"
    t.string "proxy_hostname"
    t.string "proxy_org"
    t.string "user_agent"
    t.string "resolution"
    t.string "language"
    t.string "os"
    t.integer "liked_by_count"
    t.datetime "liked_by_count_updated_at"
    t.datetime "last_matched_at"
    t.datetime "status_updated_at"
    t.bigint "schedule_id"
    t.integer "one_time_schedule_id"
    t.datetime "gologin_synced_at"
    t.datetime "status_checked_at"
    t.boolean "disable_images", default: false, null: false
    t.boolean "proxy_active", default: true, null: false
    t.string "proxy_host"
    t.string "proxy_mode"
    t.integer "proxy_port"
    t.string "proxy_username"
    t.string "proxy_password"
    t.string "proxy_auto_region"
    t.string "proxy_tor_region"
    t.integer "status_check_schedule_id"
    t.boolean "warm_up", default: false, null: false
    t.index ["fan_model_id"], name: "index_tinder_accounts_on_fan_model_id"
    t.index ["location_id", "user_id", "fan_model_id"], name: "location_user_fan", unique: true
    t.index ["location_id"], name: "index_tinder_accounts_on_location_id"
    t.index ["schedule_id"], name: "index_tinder_accounts_on_schedule_id"
    t.index ["status"], name: "index_tinder_accounts_on_status"
    t.index ["user_id"], name: "index_tinder_accounts_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "telegram_channel"
    t.string "gologin_api_token"
    t.string "name", null: false
    t.boolean "admin", default: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.string "confirmation_token"
    t.datetime "confirmed_at"
    t.datetime "confirmation_sent_at"
    t.string "unconfirmed_email"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tg_username"
    t.integer "employer_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["gologin_api_token"], name: "index_users_on_gologin_api_token", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["telegram_channel"], name: "index_users_on_telegram_channel", unique: true
  end

  add_foreign_key "account_status_updates", "swipe_jobs"
  add_foreign_key "account_status_updates", "tinder_accounts"
  add_foreign_key "fan_models", "users"
  add_foreign_key "locations", "users"
  add_foreign_key "matches", "tinder_accounts"
  add_foreign_key "runs", "swipe_jobs"
  add_foreign_key "schedules", "users"
  add_foreign_key "swipe_jobs", "schedules"
  add_foreign_key "swipe_jobs", "tinder_accounts"
  add_foreign_key "swipe_jobs", "users"
  add_foreign_key "tinder_accounts", "fan_models"
  add_foreign_key "tinder_accounts", "locations"
  add_foreign_key "tinder_accounts", "schedules"
  add_foreign_key "tinder_accounts", "schedules", column: "one_time_schedule_id"
  add_foreign_key "tinder_accounts", "schedules", column: "status_check_schedule_id"
  add_foreign_key "tinder_accounts", "users"
  add_foreign_key "users", "users", column: "employer_id"
end
