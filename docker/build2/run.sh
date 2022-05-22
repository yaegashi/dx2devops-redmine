#!/bin/bash

set -ex

mkdir -p config
echo '{"0":{"adapter":"sqlite3"},"1":{"adapter":"mysql2"},"2":{"adapter":"postgresql"}}' >config/database.yml
bundle install
rm -rf config