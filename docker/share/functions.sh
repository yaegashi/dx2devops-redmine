WWWROOT=/home/site/wwwroot
STATICSITEDIR=$WWWROOT/staticsite
BACKUPSDIR=$WWWROOT=backups
FILESDIR=$WWWROOT/files
CONFIGDIR=$WWWROOT/config
PLUGINSDIR=$WWWROOT/plugins
PUBLICTHEMESDIR=$WWWROOT/public/themes
PUBLICPLUGINASSETSDIR=$WWWROOT/public/plugin_assets

info() {
    echo "I: $*" >&2
}

run() {
    echo "I: Running $@" >&2
    "$@"
}

symlinks() {
    info "Creating symlinks to $FILESDIR and $PUBLICPLUGINASSETSDIR"
    run mkdir -p $FILESDIR $PUBLICPLUGINASSETSDIR
    run rm -rf files public/plugin_assets
    run ln -snf $FILESDIR files
    run ln -snf $PUBLICPLUGINASSETSDIR public/plugin_assets

    info "Creating symlinks to $CONFIGDIR/*"
    for i in $CONFIGDIR/*; do
        test -f $i || continue
        run ln -snf $i config/${i##*/}
    done

    info "Creating symlinks to $PLUGINSDIR/*"
    for i in $PLUGINSDIR/*; do
        test -d $i || continue
        run ln -snf $i plugins/${i##*/}
    done

    info "Creating symlinks to $PUBLICTHEMESDIR/*"
    for i in $PUBLICTHEMESDIR/*; do
        test -d $i || continue
        run ln -snf $i public/themes/${i##*/}
    done
}
