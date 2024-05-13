get_disk() {
    type -p df &>/dev/null ||
        { err "Disk requires 'df' to function. Install 'df' to get disk info."; return; }

    df_version=$(df --version 2>&1)

    case $df_version in
        *IMitv*)   df_flags=(-P -g) ;; # AIX
        *befhikm*) df_flags=(-P -k) ;; # IRIX
        *hiklnP*)  df_flags=(-h)    ;; # OpenBSD

        *Tracker*) # Haiku
            err "Your version of df cannot be used due to the non-standard flags"
            return
        ;;

        *) df_flags=(-P -h) ;;
    esac

    # Create an array called 'disks' where each element is a separate line from
    # df's output. We then unset the first element which removes the column titles.
    IFS=$'\n' read -d "" -ra disks <<< "$(df "${df_flags[@]}" "${disk_show[@]:-/}")"
    unset "disks[0]"

    # Stop here if 'df' fails to print disk info.
    [[ ${disks[*]} ]] || {
        err "Disk: df failed to print the disks, make sure the disk_show array is set properly."
        return
    }

    for disk in "${disks[@]}"; do
        # Create a second array and make each element split at whitespace this time.
        IFS=" " read -ra disk_info <<< "$disk"
        disk_perc=${disk_info[${#disk_info[@]} - 2]/\%}

        case $disk_percent in
            off) disk_perc=
        esac

        case $df_version in
            *befhikm*)
                disk=$((disk_info[${#disk_info[@]} - 4] / 1024 / 1024))G
                disk+=" / "
                disk+=$((disk_info[${#disk_info[@]} - 5] / 1024/ 1024))G
                disk+=${disk_perc:+ ($disk_perc%)}
            ;;

            *)
                disk=${disk_info[${#disk_info[@]} - 4]/i}
                disk+=" / "
                disk+=${disk_info[${#disk_info[@]} - 5]/i}
                disk+=${disk_perc:+ ($disk_perc%)}
            ;;
        esac

        case $disk_subtitle in
            name)
                disk_sub=${disk_info[*]::${#disk_info[@]} - 5}
            ;;

            dir)
                disk_sub=${disk_info[${#disk_info[@]} - 1]/*\/}
                disk_sub=${disk_sub:-${disk_info[${#disk_info[@]} - 1]}}
            ;;

            none) ;;

            *)
                disk_sub=${disk_info[${#disk_info[@]} - 1]}
            ;;
        esac

        case $disk_display in
            bar)     disk="$(bar "$disk_perc" "100")" ;;
            infobar) disk+=" $(bar "$disk_perc" "100")" ;;
            barinfo) disk="$(bar "$disk_perc" "100")${info_color} $disk" ;;
            perc)    disk="${disk_perc}% $(bar "$disk_perc" "100")" ;;
        esac

        # Append '(disk mount point)' to the subtitle.
        if [[ "$subtitle" ]]; then
            prin "$subtitle${disk_sub:+ ($disk_sub)}" "$disk"
        else
            prin "$disk_sub" "$disk"
        fi
    done
}

