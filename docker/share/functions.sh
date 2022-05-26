info() {
    echo "I: $*" >&2
}

run() {
    echo "I: Running $@" >&2
    "$@"
}
