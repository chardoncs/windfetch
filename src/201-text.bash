# TEXT FORMATTING

info() {
    # Save subtitle value.
    [[ "$2" ]] && subtitle="$1"

    # Make sure that $prin is unset.
    unset -v prin

    # Call the function.
    "get_${2:-$1}"

    # If the get_func function called 'prin' directly, stop here.
    [[ "$prin" ]] && return

    # Update the variable.
    if [[ "$2" ]]; then
        output="$(trim "${!2}")"
    else
        output="$(trim "${!1}")"
    fi

    if [[ "$2" && "${output// }" ]]; then
        prin "$1" "$output"

    elif [[ "${output// }" ]]; then
        prin "$output"

    else
        err "Info: Couldn't detect ${1}."
    fi

    unset -v subtitle
}

prin() {
    # If $2 doesn't exist we format $1 as info.
    if [[ "$(trim "$1")" && "$2" ]]; then
        [[ "$json" ]] && { printf '    %s\n' "\"${1}\": \"${2}\","; return; }

        string="${1}${2:+: $2}"
    else
        string="${2:-$1}"
        local subtitle_color="$info_color"
    fi

    string="$(trim "${string//$'\e[0m'}")"
    length="$(strip_sequences "$string")"
    length="${#length}"

    # Format the output.
    string="${string/:/${reset}${colon_color}${separator:=:}${info_color}}"
    string="${subtitle_color}${bold}${string}"

    # Print the info.
    printf '%b\n' "${text_padding:+\e[${text_padding}C}${zws}${string//\\n}${reset} "

    # Calculate info height.
    ((++info_height))

    # Log that prin was used.
    prin=1
}

get_underline() {
    [[ "$underline_enabled" == "on" ]] && {
        printf -v underline "%${length}s"
        printf '%b%b\n' "${text_padding:+\e[${text_padding}C}${zws}${underline_color}" \
                        "${underline// /$underline_char}${reset} "
    }

    ((++info_height))
    length=
    prin=1
}

get_bold() {
    case $ascii_bold in
        "on")  ascii_bold='\e[1m' ;;
        "off") ascii_bold="" ;;
    esac

    case $bold in
        "on")  bold='\e[1m' ;;
        "off") bold="" ;;
    esac
}

trim() {
    set -f
    # shellcheck disable=2048,2086
    set -- $*
    printf '%s\n' "${*//[[:space:]]/}"
    set +f
}

trim_quotes() {
    trim_output="${1//\'}"
    trim_output="${trim_output//\"}"
    printf "%s" "$trim_output"
}

strip_sequences() {
    strip="${1//$'\e['3[0-9]m}"
    strip="${strip//$'\e['[0-9]m}"
    strip="${strip//\\e\[[0-9]m}"
    strip="${strip//$'\e['38\;5\;[0-9]m}"
    strip="${strip//$'\e['38\;5\;[0-9][0-9]m}"
    strip="${strip//$'\e['38\;5\;[0-9][0-9][0-9]m}"

    printf '%s\n' "$strip"
}

