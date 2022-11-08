#!/bin/bash

while true; do
    DEBUG=1 RAILS_ENV=production rails sync_existing_gologins
    RAILS_ENV=production rails sync_new_gologins
    sleep 600
done
