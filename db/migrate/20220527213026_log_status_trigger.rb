class LogStatusTrigger < ActiveRecord::Migration[7.0]
  def change
    execute <<-SQL
  CREATE FUNCTION log_account_status_update() RETURNS trigger AS $$
       BEGIN
         IF TG_OP = 'UPDATE' AND NEW.status <> OLD.status
         THEN
           INSERT INTO account_status_updates (tinder_account_id, status, created_at, updated_at)
           VALUES (NEW.id, NEW.status, timezone('utc', now()), timezone('utc', now()));
           RETURN NEW;
         ELSE
          RETURN NEW;
         END IF;
       END;
  $$ LANGUAGE 'plpgsql' SECURITY DEFINER;

  CREATE TRIGGER t AFTER UPDATE ON tinder_accounts
          FOR EACH ROW WHEN (pg_trigger_depth() < 1) EXECUTE PROCEDURE log_account_status_update();
    SQL
  end
end
