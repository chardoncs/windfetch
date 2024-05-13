# Entry point
main() {
    cache_uname
    get_os

    # Load default config.
    eval "$config"

    get_args "$@"
    [[ $verbose != on ]] && exec 2>/dev/null
    get_simple "$@"
    get_distro
    get_bold
    get_distro_ascii
    [[ $stdout == on ]] && stdout

    # Minix doesn't support these sequences.
    [[ $TERM != minix && $stdout != on ]] && {
        # If the script exits for any reason, unhide the cursor.
        trap 'printf "\e[?25h\e[?7h"' EXIT

        # Hide the cursor and disable line wrap.
        printf '\e[?25l\e[?7l'
    }

    image_backend
    get_cache_dir
    old_functions
    print_info
    dynamic_prompt

    # w3m-img: Draw the image a second time to fix
    # rendering issues in specific terminal emulators.
    [[ $image_backend == *w3m* ]] && display_image
    [[ $image_backend == *ueberzug* ]] && display_image

    # Add windfetch info to verbose output.
    err "Windfetch command: $0 $*"
    err "Windfetch version: $version"

    [[ $verbose == on ]] && printf '%b\033[m' "$err" >&2

    # If `--loop` was used, constantly redraw the image.
    while [[ $image_loop == on && $image_backend == w3m ]]; do
        display_image
        sleep 1
    done

    return 0
}

main "$@"
