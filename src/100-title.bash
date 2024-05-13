get_title() {
    user=${USER:-$(id -un || printf %s "${HOME/*\/}")}

    case $title_fqdn in
        on) hostname=$(hostname -f) ;;
        *)  hostname=${HOSTNAME:-$(hostname)} ;;
    esac

    title=${title_color}${bold}${user}${at_color}@${title_color}${bold}${hostname}
    length=$((${#user} + ${#hostname} + 1))
}

