#!/bin/bash

set -e

. /docker/share/functions.sh

symlinks

if test -z "$SECRET_KEY_BASE"; then
    info "Initializing SECRET_KEY_BASE variable"
    export SECRET_KEY_BASE=$(ruby -rsecurerandom -e 'puts SecureRandom.hex(64)')
fi

if test -n "$DATABASE_URL" -a ! -e config/database.yml ; then
    info "Creating config/database.yml"
    run echo '{"0":{"adapter":"'${DATABASE_URL%%:*}'"}}' >config/database.yml
fi

info "Starting OpenSSH server"
mkdir -p /root/.ssh
env >/root/.ssh/environment
run /usr/sbin/sshd

if test $# -gt 0; then
    info "Command line specified"
    run "$@"
elif test -n "$RAILS_IN_SERVICE"; then
    info "Rails in service: true"
    info "Starting rails server..."
    run rm -f tmp/pids/server.pid
    run rails server -b 0.0.0.0 -p 8080
else
    info "Rails in service: false"
    if ! test -r $STATICSITEDIR/index.html; then
        info "Creating $STATICSITEDIR"
        mkdir -p $STATICSITEDIR
        echo "Maintenance mode" >$STATICSITEDIR/index.html
    fi
    info "Starting static site server..."
    run ruby -run -e httpd $STATICSITEDIR -p 8080
fi
