#!/bin/bash
source "/usr/local/rvm/scripts/rvm"
cd /app
exec bundle exec thin start --rackup config/resque_web.ru --address 127.0.0.1 --port 5678
