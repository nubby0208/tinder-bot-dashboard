#!/bin/bash
set -eu

if [ $(hostname) = "bijan-ubuntu22" ]; then
    ssh bijan@65.108.104.217  "pg_dump tinderbot_prod -C  --column-inserts"  > prod.sql
    DISABLE_DATABASE_ENVIRONMENT_CHECK=1 RAILS_ENV=production rails db:drop db:create
    psql tinderbot_prod < prod.sql
    rsync -avz bijan@65.108.104.217:tinderbot2/rails/public/screenshots public/
    rsync -avz bijan@65.108.104.217:tinderbot2/logs /home/bijan/tinderbot2
    # rsync -avz bijan@65.108.104.217:/var/www/videos /var/www
else
    echo "hostname not correct"
    exit 2
fi
