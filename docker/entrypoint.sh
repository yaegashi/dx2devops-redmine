#!/bin/bash

WWWROOT=/home/site/wwwroot
STATICSITEDIR=$WWWROOT/staticsite
BACKUPSDIR=$WWWROOT=backups
FILESDIR=$WWWROOT/files
PLUGINSDIR=$WWWROOT/plugins
PUBLICTHEMESDIR=$WWWROOT/public/themes
PUBLICPLUGINASSETSDIR=$WWWROOT/public/plugin_assets

set -ex

if test -n "$DATABASE_URL" -a ! -e config/database.yml ; then
    echo '{"0":{"adapter":"'${DATABASE_URL%%:*}'"}}' >config/database.yml
fi

if test -z "$SECRET_KEY_BASE"; then
    export SECRET_KEY_BASE=$(ruby -rsecurerandom -e 'puts SecureRandom.hex(64)')
fi

mkdir -p $FILESDIR $PUBLICPLUGINASSETSDIR
rm -rf files public/plugin_assets
ln -snf $FILESDIR files
ln -snf $PUBLICPLUGINASSETSDIR public/plugin_assets

for i in $PLUGINSDIR/*; do
    test -d $i || continue
    ln -snf $i plugins/${i##*/}
done

for i in $PUBLICTHEMESDIR/*; do
    test -d $i || continue
    ln -snf $i public/themes/${i##*/}
done

mkdir -p /root/.ssh
env >/root/.ssh/environment
/usr/sbin/sshd

set +x
if test $# -gt 0; then
    echo "Running command line: $@"
    "$@"
elif test -n "$RAILS_IN_SERVICE"; then
    echo "Rails in service: true" >&2
    echo "Starting rails server..." >&2
    rm -f tmp/pids/server.pid
    rails server -b 0.0.0.0 -p 8080
else
    echo "Rails in service: false" >&2
    echo "Starting static site server..." >&2
    mkdir -p $STATICSITEDIR
    echo "Maintenance mode" >$STATICSITEDIR/index.html
    ruby -run -e httpd $STATICSITEDIR -p 8080
fi
