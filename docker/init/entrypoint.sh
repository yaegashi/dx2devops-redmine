#!/bin/bash

WWWROOT=/home/site/wwwroot
STATICSITEDIR=$WWWROOT/staticsite
BACKUPSDIR=$WWWROOT=backups
FILESDIR=$WWWROOT/files
CONFIGDIR=$WWWROOT/config
PLUGINSDIR=$WWWROOT/plugins
PUBLICTHEMESDIR=$WWWROOT/public/themes
PUBLICPLUGINASSETSDIR=$WWWROOT/public/plugin_assets

set -e

. /docker/share/functions.sh

if test -z "$SECRET_KEY_BASE"; then
    info "Initializing SECRET_KEY_BASE variable"
    export SECRET_KEY_BASE=$(ruby -rsecurerandom -e 'puts SecureRandom.hex(64)')
fi

info "Creating symlinks to $FILESDIR and $PUBLICPLUGINASSETSDIR"
run mkdir -p $FILESDIR $PUBLICPLUGINASSETSDIR
run rm -rf files public/plugin_assets
run ln -snf $FILESDIR files
run ln -snf $PUBLICPLUGINASSETSDIR public/plugin_assets

info "Creating symlinks to $CONFIGDIR/*"
for i in $CONFIGDIR/*; do
    test -d $i || continue
    run ln -snf $i config/${i##*/}
done

if test -n "$DATABASE_URL" -a ! -e config/database.yml ; then
    info "Creating config/database.yml"
    run echo '{"0":{"adapter":"'${DATABASE_URL%%:*}'"}}' >config/database.yml
fi

info "Creating symlinks to $PLUGINSDIR/*"
for i in $PLUGINSDIR/*; do
    test -d $i || continue
    run ln -snf $i plugins/${i##*/}
done

info "Creating symlinks to $PUBLICPLUGINASSETSDIR/*"
for i in $PUBLICTHEMESDIR/*; do
    test -d $i || continue
    run ln -snf $i public/themes/${i##*/}
done

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
