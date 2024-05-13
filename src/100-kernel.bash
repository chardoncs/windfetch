get_kernel() {
    # Since these OS are integrated systems, it's better to skip this function altogether
    [[ $os =~ (AIX|IRIX) ]] && return

    # Haiku uses 'uname -v' and not - 'uname -r'.
    [[ $os == Haiku ]] && {
        kernel=$(uname -v)
        return
    }

    # In Windows 'uname' may return the info of GNUenv thus use wmic for OS kernel.
    [[ $os == Windows ]] && {
        kernel=$(wmic os get Version)
        kernel=${kernel/Version}
        return
    }

    case $kernel_shorthand in
        on)  kernel=$kernel_version ;;
        off) kernel="$kernel_name $kernel_version" ;;
    esac

    # Hide kernel info if it's identical to the distro info.
    [[ $os =~ (BSD|MINIX) && $distro == *"$kernel_name"* ]] &&
        case $distro_shorthand in
            on|tiny) kernel=$kernel_version ;;
            *)       unset kernel ;;
        esac
}

