get_uptime() {
    # Get uptime in seconds.
    case $os in
        Linux|Windows|MINIX)
            if [[ -r /proc/uptime ]]; then
                s=$(< /proc/uptime)
                s=${s/.*}
            else
                boot=$(date -d"$(uptime -s)" +%s)
                now=$(date +%s)
                s=$((now - boot))
            fi
        ;;

        "Mac OS X"|"macOS"|"iPhone OS"|BSD|FreeMiNT)
            boot=$(sysctl -n kern.boottime)
            boot=${boot/\{ sec = }
            boot=${boot/,*}

            # Get current date in seconds.
            now=$(date +%s)
            s=$((now - boot))
        ;;

        Solaris)
            s=$(kstat -p unix:0:system_misc:snaptime | awk '{print $2}')
            s=${s/.*}
        ;;

        AIX|IRIX)
            t=$(LC_ALL=POSIX ps -o etime= -p 1)

            [[ $t == *-*   ]] && { d=${t%%-*}; t=${t#*-}; }
            [[ $t == *:*:* ]] && { h=${t%%:*}; t=${t#*:}; }

            h=${h#0}
            t=${t#0}

            s=$((${d:-0}*86400 + ${h:-0}*3600 + ${t%%:*}*60 + ${t#*:}))
        ;;

        Haiku)
            s=$(($(system_time) / 1000000))
        ;;
    esac

    d="$((s / 60 / 60 / 24)) days"
    h="$((s / 60 / 60 % 24)) hours"
    m="$((s / 60 % 60)) minutes"

    # Remove plural if < 2.
    ((${d/ *} == 1)) && d=${d/s}
    ((${h/ *} == 1)) && h=${h/s}
    ((${m/ *} == 1)) && m=${m/s}

    # Hide empty fields.
    ((${d/ *} == 0)) && unset d
    ((${h/ *} == 0)) && unset h
    ((${m/ *} == 0)) && unset m

    uptime=${d:+$d, }${h:+$h, }$m
    uptime=${uptime%', '}
    uptime=${uptime:-$s seconds}

    # Make the output of uptime smaller.
    case $uptime_shorthand in
        on)
            uptime=${uptime/ minutes/ mins}
            uptime=${uptime/ minute/ min}
            uptime=${uptime/ seconds/ secs}
        ;;

        tiny)
            uptime=${uptime/ days/d}
            uptime=${uptime/ day/d}
            uptime=${uptime/ hours/h}
            uptime=${uptime/ hour/h}
            uptime=${uptime/ minutes/m}
            uptime=${uptime/ minute/m}
            uptime=${uptime/ seconds/s}
            uptime=${uptime//,}
        ;;
    esac
}

