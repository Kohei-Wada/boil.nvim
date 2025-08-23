main () {
    echo "DEBUG: Starting command execution"
    {{__selection__}}
    echo "DEBUG: Command completed with exit code: $?"
}

main "$@"
