#!/bin/bash
set -eu

if [ $(hostname) != "Ubuntu-2204-jammy-amd64-base" ]; then
    ssh bijan@65.108.104.217  "pg_dump tinderbot_prod -C --column-inserts"  > prod.sql
    sed -i '' -e 's/production/development/' ./prod.sql
    sed -i '' -e 's/prod/dev/' ./prod.sql
    rails db:drop db:create
    psql tinderbot_dev < prod.sql
    rsync -avz bijan@65.108.104.217:tinderbot2/rails/public/screenshots public/
    rsync -avz bijan@65.108.104.217:tinderbot2/logs ..
    # rsync -avz bijan@65.108.104.217:/var/www/videos /var/www
else
    echo "are you trying to run this on production?"
    exit 2
fi
