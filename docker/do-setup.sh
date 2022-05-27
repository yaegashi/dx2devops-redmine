#!/bin/bash

. /docker/share/functions.sh

cd /redmine

symlinks

run rake db:migrate

run rake redmine:plugins:migrate
