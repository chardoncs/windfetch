get_args() {
    # Check the commandline flags early for '--config'.
    [[ "$*" != *--config* && "$*" != *--no_config* ]] && get_user_config

    while [[ "$1" ]]; do
        case $1 in
            # Info
            "--title_fqdn") title_fqdn="$2" ;;
            "--package_managers") package_managers="$2" ;;
            "--os_arch") os_arch="$2" ;;
            "--cpu_cores") cpu_cores="$2" ;;
            "--cpu_speed") cpu_speed="$2" ;;
            "--speed_type") speed_type="$2" ;;
            "--speed_shorthand") speed_shorthand="$2" ;;
            "--distro_shorthand") distro_shorthand="$2" ;;
            "--kernel_shorthand") kernel_shorthand="$2" ;;
            "--uptime_shorthand") uptime_shorthand="$2" ;;
            "--cpu_brand") cpu_brand="$2" ;;
            "--gpu_brand") gpu_brand="$2" ;;
            "--gpu_type") gpu_type="$2" ;;
            "--refresh_rate") refresh_rate="$2" ;;
            "--de_version") de_version="$2" ;;
            "--gtk_shorthand") gtk_shorthand="$2" ;;
            "--gtk2") gtk2="$2" ;;
            "--gtk3") gtk3="$2" ;;
            "--shell_path") shell_path="$2" ;;
            "--shell_version") shell_version="$2" ;;
            "--ip_host") public_ip_host="$2" ;;
            "--ip_timeout") public_ip_timeout="$2" ;;
            "--ip_interface")
                unset local_ip_interface
                for arg in "$@"; do
                    case "$arg" in
                        "--ip_interface") ;;
                        "-"*) break ;;
                        *) local_ip_interface+=("$arg") ;;
                    esac
                done
            ;;

            "--song_format") song_format="$2" ;;
            "--song_shorthand") song_shorthand="$2" ;;
            "--music_player") music_player="$2" ;;
            "--memory_percent") memory_percent="$2" ;;
            "--memory_unit") memory_unit="$2" ;;
            "--cpu_temp")
                cpu_temp="$2"
                [[ "$cpu_temp" == "on" ]] && cpu_temp="C"
            ;;

            "--disk_subtitle") disk_subtitle="$2" ;;
            "--disk_percent")  disk_percent="$2" ;;
            "--disk_show")
                unset disk_show
                for arg in "$@"; do
                    case $arg in
                        "--disk_show") ;;
                        "-"*) break ;;
                        *) disk_show+=("$arg") ;;
                    esac
                done
            ;;

            "--disable")
                for func in "$@"; do
                    case $func in
                        "--disable") continue ;;
                        "-"*) break ;;
                        *)
                            ((bash_version >= 4)) && func="${func,,}"
                            unset -f "get_$func"
                        ;;
                    esac
                done
            ;;

            # Text Colors
            "--colors")
                unset colors
                for arg in "$2" "$3" "$4" "$5" "$6" "$7"; do
                    case $arg in
                        "-"*) break ;;
                        *) colors+=("$arg") ;;
                    esac
                done
                colors+=(7 7 7 7 7 7)
            ;;

            # Text Formatting
            "--underline") underline_enabled="$2" ;;
            "--underline_char") underline_char="$2" ;;
            "--bold") bold="$2" ;;
            "--separator") separator="$2" ;;

            # Color Blocks
            "--color_blocks") color_blocks="$2" ;;
            "--block_range") block_range=("$2" "$3") ;;
            "--block_width") block_width="$2" ;;
            "--block_height") block_height="$2" ;;
            "--col_offset") col_offset="$2" ;;

            # Bars
            "--bar_char")
                bar_char_elapsed="$2"
                bar_char_total="$3"
            ;;

            "--bar_border") bar_border="$2" ;;
            "--bar_length") bar_length="$2" ;;
            "--bar_colors")
                bar_color_elapsed="$2"
                bar_color_total="$3"
            ;;

            "--memory_display") memory_display="$2" ;;
            "--battery_display") battery_display="$2" ;;
            "--disk_display") disk_display="$2" ;;

            # Image backend
            "--backend") image_backend="$2" ;;
            "--source") image_source="$2" ;;
            "--ascii" | "--caca" | "--catimg" | "--chafa" | "--jp2a" | "--iterm2" | "--off" |\
            "--pot" | "--pixterm" | "--sixel" | "--termpix" | "--tycat" | "--w3m" | "--kitty" |\
            "--ueberzug" | "--viu")
                image_backend="${1/--}"
                case $2 in
                    "-"* | "") ;;
                    *) image_source="$2" ;;
                esac
            ;;

            # Image options
            "--loop") image_loop="on" ;;
            "--image_size" | "--size") image_size="$2" ;;
            "--catimg_size") catimg_size="$2" ;;
            "--crop_mode") crop_mode="$2" ;;
            "--crop_offset") crop_offset="$2" ;;
            "--xoffset") xoffset="$2" ;;
            "--yoffset") yoffset="$2" ;;
            "--background_color" | "--bg_color") background_color="$2" ;;
            "--gap") gap="$2" ;;
            "--clean")
                [[ -d "$thumbnail_dir" ]] && rm -rf "$thumbnail_dir"
                rm -rf "/Library/Caches/windfetch/"
                rm -rf "/tmp/windfetch/"
                exit
            ;;

            "--ascii_colors")
                unset ascii_colors
                for arg in "$2" "$3" "$4" "$5" "$6" "$7"; do
                    case $arg in
                        "-"*) break ;;
                        *) ascii_colors+=("$arg")
                    esac
                done
                ascii_colors+=(7 7 7 7 7 7)
            ;;

            "--ascii_distro")
                image_backend="ascii"
                ascii_distro="$2"
            ;;

            "--ascii_bold") ascii_bold="$2" ;;
            "--logo" | "-L")
                image_backend="ascii"
                print_info() { printf '\n'; }
            ;;

            # Other
            "--config")
                case $2 in
                    "none" | "off" | "") ;;
                    *)
                        config_file="$(get_full_path "$2")"
                        get_user_config
                    ;;
                esac
            ;;
            "--no_config") no_config="on" ;;
            "--stdout") stdout="on" ;;
            "-v") verbose="on" ;;
            "--print_config") printf '%s\n' "$config"; exit ;;
            "-vv") set -x; verbose="on" ;;
            "--help") usage ;;
            "--version")
                printf '%s\n' "Windfetch $version"
                exit 1
            ;;
            "--gen-man")
                help2man -n "A fast, highly customizable system info script" \
                          -N ./windfetch -o windfetch.1
                exit 1
            ;;

            "--json")
                json="on"
                unset -f get_title get_cols get_underline

                printf '{\n'
                print_info 2>/dev/null
                printf '    %s\n' "\"Version\": \"${version}\""
                printf '}\n'
                exit
            ;;

            "--travis")
                print_info() {
                    info title
                    info underline

                    info "OS" distro
                    info "Host" model
                    info "Kernel" kernel
                    info "Uptime" uptime
                    info "Packages" packages
                    info "Shell" shell
                    info "Resolution" resolution
                    info "DE" de
                    info "WM" wm
                    info "WM Theme" wm_theme
                    info "Theme" theme
                    info "Icons" icons
                    info "Terminal" term
                    info "Terminal Font" term_font
                    info "CPU" cpu
                    info "GPU" gpu
                    info "GPU Driver" gpu_driver
                    info "Memory" memory

                    info "Disk" disk
                    info "Battery" battery
                    info "Font" font
                    info "Song" song
                    info "Local IP" local_ip
                    info "Public IP" public_ip
                    info "Users" users

                    info cols

                    # Testing.
                    prin "prin"
                    prin "prin" "prin"

                    # Testing no subtitles.
                    info uptime
                    info disk
                }

                refresh_rate="on"
                shell_version="on"
                memory_display="infobar"
                disk_display="infobar"
                cpu_temp="C"

                # Known implicit unused variables.
                mpc_args=()
                printf '%s\n' "$kernel $icons $font $battery $locale ${mpc_args[*]}"
            ;;
        esac

        shift
    done
}

