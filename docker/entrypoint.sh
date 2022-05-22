#!/bin/bash

WWWROOT=/home/site/wwwroot
FILESDIR=$WWWROOT/files
MAINTDIR=$WWWROOT/maint

set -ex

abort() {
    set +x
    mkdir -p $MAINTDIR
    echo "Maintenance mode: $*" >$MAINTDIR/index.html
    cat $MAINTDIR/index.html >&2
    echo "Starting maintenance server..." >&2
    ruby -run -e httpd $MAINTDIR -p 8080
    exit $?
}

if test $# -gt 0; then
    "$@"
    exit $?
fi

if test -n "$DATABASE_URL" -a ! -e config/database.yml ; then
    echo '{"0":{"adapter":"'${DATABASE_URL%%:*}'"}}' >config/database.yml
fi

mkdir -p $FILESDIR $MAINTDIR
rm -rf files
ln -s $FILESDIR files

mkdir /root/.ssh
env >/root/.ssh/environment

/usr/sbin/sshd

if test -n "$RAILS_IN_SERVICE"; then
    rails server -b 0.0.0.0 -p 8080 || abort "Failed to start server: $?"
else
    abort "RAILS_IN_SERVICE is not set"
fi
