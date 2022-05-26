#!/bin/bash

. /docker/share/functions.sh

cd /redmine

run rake db:migrate

run rake redmine:plugins:migrate
