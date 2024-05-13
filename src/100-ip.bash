get_local_ip() {
    case $os in
        "Linux" | "BSD" | "Solaris" | "AIX" | "IRIX")
            if [[ "${local_ip_interface[0]}" == "auto" ]]; then
                local_ip="$(ip route get 1 | awk -F'src' '{print $2; exit}')"
                local_ip="${local_ip/uid*}"
                [[ "$local_ip" ]] || local_ip="$(ifconfig -a | awk '/broadcast/ {print $2; exit}')"
            else
                for interface in "${local_ip_interface[@]}"; do
                    local_ip="$(ip addr show "$interface" 2> /dev/null |
                        awk '/inet / {print $2; exit}')"
                    local_ip="${local_ip/\/*}"
                    [[ "$local_ip" ]] ||
                        local_ip="$(ifconfig "$interface" 2> /dev/null |
                        awk '/broadcast/ {print $2; exit}')"
                    if [[ -n "$local_ip" ]]; then
                        prin "$interface" "$local_ip"
                    else
                        err "Local IP: Could not detect local ip for $interface"
                    fi
                done
            fi
        ;;

        "MINIX")
            local_ip="$(ifconfig | awk '{printf $3; exit}')"
        ;;

        "Mac OS X" | "macOS" | "iPhone OS")
            if [[ "${local_ip_interface[0]}" == "auto" ]]; then
                interface="$(route get 1 | awk -F': ' '/interface/ {printf $2; exit}')"
                local_ip="$(ipconfig getifaddr "$interface")"
            else
                for interface in "${local_ip_interface[@]}"; do
                    local_ip="$(ipconfig getifaddr "$interface")"
                    if [[ -n "$local_ip" ]]; then
                        prin "$interface" "$local_ip"
                    else
                        err "Local IP: Could not detect local ip for $interface"
                    fi
                done
            fi
        ;;

        "Windows")
            local_ip="$(ipconfig | awk -F ': ' '/IPv4 Address/ {printf $2 ", "}')"
            local_ip="${local_ip%\,*}"
        ;;

        "Haiku")
            local_ip="$(ifconfig | awk -F ': ' '/Bcast/ {print $2}')"
            local_ip="${local_ip/, Bcast}"
        ;;
    esac
}

get_public_ip() {
    if [[ ! -n "$public_ip_host" ]] && type -p dig >/dev/null; then
        public_ip="$(dig +time=1 +tries=1 +short myip.opendns.com @resolver1.opendns.com)"
       [[ "$public_ip" =~ ^\; ]] && unset public_ip
    fi

    if [[ ! -n "$public_ip_host" ]] && [[ -z "$public_ip" ]] && type -p drill >/dev/null; then
        public_ip="$(drill myip.opendns.com @resolver1.opendns.com | \
                     awk '/^myip\./ && $3 == "IN" {print $5}')"
    fi

    if [[ -z "$public_ip" ]] && type -p curl >/dev/null; then
        public_ip="$(curl -L --max-time "$public_ip_timeout" -w '\n' "$public_ip_host")"
    fi

    if [[ -z "$public_ip" ]] && type -p wget >/dev/null; then
        public_ip="$(wget -T "$public_ip_timeout" -qO- "$public_ip_host")"
    fi
}

