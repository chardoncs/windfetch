# OTHER

stdout() {
    image_backend="off"
    unset subtitle_color colon_color info_color underline_color bold title_color at_color \
          text_padding zws reset color_blocks bar_color_elapsed bar_color_total \
          c1 c2 c3 c4 c5 c6 c7 c8
}

err() {
    err+="$(color 1)[!]${reset} $1
"
}

get_full_path() {
    # This function finds the absolute path from a relative one.
    # For example "Pictures/Wallpapers" --> "/home/dylan/Pictures/Wallpapers"

    # If the file exists in the current directory, stop here.
    [[ -f "${PWD}/${1}" ]] && { printf '%s\n' "${PWD}/${1}"; return; }

    ! cd "${1%/*}" && {
        err "Error: Directory '${1%/*}' doesn't exist or is inaccessible"
        err "       Check that the directory exists or try another directory."
        exit 1
    }

    local full_dir="${1##*/}"

    # Iterate down a (possible) chain of symlinks.
    while [[ -L "$full_dir" ]]; do
        full_dir="$(readlink "$full_dir")"
        cd "${full_dir%/*}" || exit
        full_dir="${full_dir##*/}"
    done

    # Final directory.
    full_dir="$(pwd -P)/${1/*\/}"

    [[ -e "$full_dir" ]] && printf '%s\n' "$full_dir"
}

get_user_config() {
    # --config /path/to/config.conf
    if [[ -f "$config_file" ]]; then
        source "$config_file"
        err "Config: Sourced user config. (${config_file})"
        return

    elif [[ -f "${XDG_CONFIG_HOME}/neofetch/config.conf" ]]; then
        source "${XDG_CONFIG_HOME}/neofetch/config.conf"
        err "Config: Sourced user config.    (${XDG_CONFIG_HOME}/neofetch/config.conf)"

    elif [[ -f "${XDG_CONFIG_HOME}/neofetch/config" ]]; then
        source "${XDG_CONFIG_HOME}/neofetch/config"
        err "Config: Sourced user config.    (${XDG_CONFIG_HOME}/neofetch/config)"

    elif [[ -z "$no_config" ]]; then
        config_file="${XDG_CONFIG_HOME}/neofetch/config.conf"

        # The config file doesn't exist, create it.
        mkdir -p "${XDG_CONFIG_HOME}/neofetch/"
        printf '%s\n' "$config" > "$config_file"
    fi
}

bar() {
    # Get the values.
    elapsed="$(($1 * bar_length / $2))"

    # Create the bar with spaces.
    printf -v prog  "%${elapsed}s"
    printf -v total "%$((bar_length - elapsed))s"

    # Set the colors and swap the spaces for $bar_char_.
    bar+="${bar_color_elapsed}${prog// /${bar_char_elapsed}}"
    bar+="${bar_color_total}${total// /${bar_char_total}}"

    # Borders.
    [[ "$bar_border" == "on" ]] && \
        bar="$(color fg)[${bar}$(color fg)]"

    printf "%b" "${bar}${info_color}"
}

cache() {
    if [[ "$2" ]]; then
        mkdir -p "${cache_dir}/neofetch"
        printf "%s" "${1/*-}=\"$2\"" > "${cache_dir}/neofetch/${1/*-}"
    fi
}

get_cache_dir() {
    case $os in
        "Mac OS X"|"macOS") cache_dir="/Library/Caches" ;;
        *)          cache_dir="/tmp" ;;
    esac
}

kde_config_dir() {
    # If the user is using KDE get the KDE
    # configuration directory.
    if [[ "$kde_config_dir" ]]; then
        return

    elif type -p kf5-config &>/dev/null; then
        kde_config_dir="$(kf5-config --path config)"

    elif type -p kde4-config &>/dev/null; then
        kde_config_dir="$(kde4-config --path config)"

    elif type -p kde-config &>/dev/null; then
        kde_config_dir="$(kde-config --path config)"

    elif [[ -d "${HOME}/.kde4" ]]; then
        kde_config_dir="${HOME}/.kde4/share/config"

    elif [[ -d "${HOME}/.kde3" ]]; then
        kde_config_dir="${HOME}/.kde3/share/config"
    fi

    kde_config_dir="${kde_config_dir/$'/:'*}"
}

term_padding() {
    # Get terminal padding to properly align cursor.
    [[ -z "$term" ]] && get_term

    case $term in
        urxvt*|rxvt-unicode)
            [[ $xrdb ]] || xrdb=$(xrdb -query)

            [[ $xrdb != *internalBorder:* ]] &&
                return

            padding=${xrdb/*internalBorder:}
            padding=${padding/$'\n'*}

            [[ $padding =~ ^[0-9]+$ ]] ||
                padding=
        ;;
    esac
}

dynamic_prompt() {
    [[ "$image_backend" == "off" ]]   && { printf '\n'; return; }
    [[ "$image_backend" != "ascii" ]] && ((lines=(height + yoffset) / font_height + 1))
    [[ "$image_backend" == "w3m" ]]   && ((lines=lines + padding / font_height + 1))

    # If the ascii art is taller than the info.
    ((lines=lines>info_height?lines-info_height+1:1))

    printf -v nlines "%${lines}s"
    printf "%b" "${nlines// /\\n}"
}

cache_uname() {
    # Cache the output of uname so we don't
    # have to spawn it multiple times.
    IFS=" " read -ra uname <<< "$(uname -srm)"

    kernel_name="${uname[0]}"
    kernel_version="${uname[1]}"
    kernel_machine="${uname[2]}"

    if [[ "$kernel_name" == "Darwin" ]]; then
        # macOS can report incorrect versions unless this is 0.
        # https://github.com/dylanaraps/neofetch/issues/1607
        export SYSTEM_VERSION_COMPAT=0

        IFS=$'\n' read -d "" -ra sw_vers <<< "$(awk -F'<|>' '/key|string/ {print $3}' \
                            "/System/Library/CoreServices/SystemVersion.plist")"
        for ((i=0;i<${#sw_vers[@]};i+=2)) {
            case ${sw_vers[i]} in
                ProductName)          darwin_name=${sw_vers[i+1]} ;;
                ProductVersion)       osx_version=${sw_vers[i+1]} ;;
                ProductBuildVersion)  osx_build=${sw_vers[i+1]}   ;;
            esac
        }
    fi
}

get_ppid() {
    # Get parent process ID of PID.
    case $os in
        "Windows")
            ppid="$(ps -p "${1:-$PPID}" | awk '{printf $2}')"
            ppid="${ppid/PPID}"
        ;;

        "Linux")
            ppid="$(grep -i -F "PPid:" "/proc/${1:-$PPID}/status")"
            ppid="$(trim "${ppid/PPid:}")"
        ;;

        *)
            ppid="$(ps -p "${1:-$PPID}" -o ppid=)"
        ;;
    esac

    printf "%s" "$ppid"
}

get_process_name() {
    # Get PID name.
    case $os in
        "Windows")
            name="$(ps -p "${1:-$PPID}" | awk '{printf $8}')"
            name="${name/COMMAND}"
            name="${name/*\/}"
        ;;

        "Linux")
            name="$(< "/proc/${1:-$PPID}/comm")"
        ;;

        *)
            name="$(ps -p "${1:-$PPID}" -o comm=)"
        ;;
    esac

    printf "%s" "$name"
}

decode_url() {
    decode="${1//+/ }"
    printf "%b" "${decode//%/\\x}"
}

