get_cpu() {
    case $os in
        "Linux" | "MINIX" | "Windows")
            # Get CPU name.
            cpu_file="/proc/cpuinfo"

            case $kernel_machine in
                "frv" | "hppa" | "m68k" | "openrisc" | "or"* | "powerpc" | "ppc"* | "sparc"*)
                    cpu="$(awk -F':' '/^cpu\t|^CPU/ {printf $2; exit}' "$cpu_file")"
                ;;

                "s390"*)
                    cpu="$(awk -F'=' '/machine/ {print $4; exit}' "$cpu_file")"
                ;;

                "ia64" | "m32r")
                    cpu="$(awk -F':' '/model/ {print $2; exit}' "$cpu_file")"
                    [[ -z "$cpu" ]] && cpu="$(awk -F':' '/family/ {printf $2; exit}' "$cpu_file")"
                ;;

                *)
                    cpu="$(awk -F '\\s*: | @' \
                            '/model name|Hardware|Processor|^cpu model|chip type|^cpu type/ {
                            cpu=$2; if ($1 == "Hardware") exit } END { print cpu }' "$cpu_file")"
                ;;
            esac

            speed_dir="/sys/devices/system/cpu/cpu0/cpufreq"

            # Select the right temperature file.
            for temp_dir in /sys/class/hwmon/*; do
                [[ "$(< "${temp_dir}/name")" =~ (cpu_thermal|coretemp|fam15h_power|k10temp) ]] && {
                    temp_dirs=("$temp_dir"/temp*_input)
                    temp_dir=${temp_dirs[0]}
                    break
                }
            done

            # Get CPU speed.
            if [[ -d "$speed_dir" ]]; then
                # Fallback to bios_limit if $speed_type fails.
                speed="$(< "${speed_dir}/${speed_type}")" ||\
                speed="$(< "${speed_dir}/bios_limit")" ||\
                speed="$(< "${speed_dir}/scaling_max_freq")" ||\
                speed="$(< "${speed_dir}/cpuinfo_max_freq")"
                speed="$((speed / 1000))"

            else
                case $kernel_machine in
                    "sparc"*)
                        # SPARC systems use a different file to expose clock speed information.
                        speed_file="/sys/devices/system/cpu/cpu0/clock_tick"
                        speed="$(($(< "$speed_file") / 1000000))"
                    ;;

                    *)
                        speed="$(awk -F ': |\\.' '/cpu MHz|^clock/ {printf $2; exit}' "$cpu_file")"
                        speed="${speed/MHz}"
                    ;;
                esac
            fi

            # Get CPU temp.
            [[ -f "$temp_dir" ]] && deg="$(($(< "$temp_dir") * 100 / 10000))"

            # Get CPU cores.
            case $kernel_machine in
                "sparc"*)
                    case $cpu_cores in
                        # SPARC systems doesn't expose detailed topology information in
                        # /proc/cpuinfo so I have to use lscpu here.
                        "logical" | "on")
                            cores="$(lscpu | awk -F ': *' '/^CPU\(s\)/ {print $2}')"
                        ;;
                        "physical")
                            cores="$(lscpu | awk -F ': *' '/^Core\(s\) per socket/ {print $2}')"
                            sockets="$(lscpu | awk -F ': *' '/^Socket\(s\)/ {print $2}')"
                            cores="$((sockets * cores))"
                        ;;
                    esac
                ;;

                *)
                    case $cpu_cores in
                        "logical" | "on")
                            cores="$(grep -c "^processor" "$cpu_file")"
                        ;;
                        "physical")
                            cores="$(awk '/^core id/&&!a[$0]++{++i} END {print i}' "$cpu_file")"
                        ;;
                    esac
                ;;
            esac
        ;;

        "Mac OS X"|"macOS")
            cpu="$(sysctl -n machdep.cpu.brand_string)"

            # Get CPU cores.
            case $cpu_cores in
                "logical" | "on") cores="$(sysctl -n hw.logicalcpu_max)" ;;
                "physical")       cores="$(sysctl -n hw.physicalcpu_max)" ;;
            esac
        ;;

        "iPhone OS")
            case $kernel_machine in
                "iPhone1,"[1-2] | "iPod1,1"): "Samsung S5L8900 (1) @ 412MHz" ;;
                "iPhone2,1"):                 "Samsung S5PC100 (1) @ 600MHz" ;;
                "iPhone3,"[1-3] | "iPod4,1"): "Apple A4 (1) @ 800MHz" ;;
                "iPhone4,1" | "iPod5,1"):     "Apple A5 (2) @ 800MHz" ;;
                "iPhone5,"[1-4]): "Apple A6 (2) @ 1.3GHz" ;;
                "iPhone6,"[1-2]): "Apple A7 (2) @ 1.3GHz" ;;
                "iPhone7,"[1-2]): "Apple A8 (2) @ 1.4GHz" ;;
                "iPhone8,"[1-4] | "iPad6,1"[12]): "Apple A9 (2) @ 1.85GHz" ;;
                "iPhone9,"[1-4] | "iPad7,"[5-6] | "iPad7,1"[1-2]):
                    "Apple A10 Fusion (4) @ 2.34GHz"
                ;;
                "iPhone10,"[1-6]): "Apple A11 Bionic (6) @ 2.39GHz" ;;
                "iPhone11,"[2468] | "iPad11,"[1-4] | "iPad11,"[6-7]): "Apple A12 Bionic (6) @ 2.49GHz" ;;
                "iPhone12,"[1358]): "Apple A13 Bionic (6) @ 2.65GHz" ;;
                "iPhone13,"[1-4] | "iPad13,"[1-2]): "Apple A14 Bionic (6) @ 3.00Ghz" ;;

                "iPod2,1"): "Samsung S5L8720 (1) @ 533MHz" ;;
                "iPod3,1"): "Samsung S5L8922 (1) @ 600MHz" ;;
                "iPod7,1"): "Apple A8 (2) @ 1.1GHz" ;;
                "iPad1,1"): "Apple A4 (1) @ 1GHz" ;;
                "iPad2,"[1-7]): "Apple A5 (2) @ 1GHz" ;;
                "iPad3,"[1-3]): "Apple A5X (2) @ 1GHz" ;;
                "iPad3,"[4-6]): "Apple A6X (2) @ 1.4GHz" ;;
                "iPad4,"[1-3]): "Apple A7 (2) @ 1.4GHz" ;;
                "iPad4,"[4-9]): "Apple A7 (2) @ 1.4GHz" ;;
                "iPad5,"[1-2]): "Apple A8 (2) @ 1.5GHz" ;;
                "iPad5,"[3-4]): "Apple A8X (3) @ 1.5GHz" ;;
                "iPad6,"[3-4]): "Apple A9X (2) @ 2.16GHz" ;;
                "iPad6,"[7-8]): "Apple A9X (2) @ 2.26GHz" ;;
                "iPad7,"[1-4]): "Apple A10X Fusion (6) @ 2.39GHz" ;;
                "iPad8,"[1-8]): "Apple A12X Bionic (8) @ 2.49GHz" ;;
                "iPad8,9" | "iPad8,1"[0-2]): "Apple A12Z Bionic (8) @ 2.49GHz" ;;
            esac
            cpu="$_"
        ;;

        "BSD")
            # Get CPU name.
            cpu="$(sysctl -n hw.model)"
            cpu="${cpu/[0-9]\.*}"
            cpu="${cpu/ @*}"

            # Get CPU speed.
            speed="$(sysctl -n hw.cpuspeed)"
            [[ -z "$speed" ]] && speed="$(sysctl -n  hw.clockrate)"

            # Get CPU cores.
            case $kernel_name in
                "OpenBSD"*)
                    [[ "$(sysctl -n hw.smt)" == "1" ]] && smt="on" || smt="off"
                    ncpufound="$(sysctl -n hw.ncpufound)"
                    ncpuonline="$(sysctl -n hw.ncpuonline)"
                    cores="${ncpuonline}/${ncpufound},\\xc2\\xa0SMT\\xc2\\xa0${smt}"
                ;;
                *)
                    cores="$(sysctl -n hw.ncpu)"
                ;;
            esac

            # Get CPU temp.
            case $kernel_name in
                "FreeBSD"* | "DragonFly"* | "NetBSD"*)
                    deg="$(sysctl -n dev.cpu.0.temperature)"
                    deg="${deg/C}"
                ;;
                "OpenBSD"* | "Bitrig"*)
                    deg="$(sysctl hw.sensors | \
                        awk -F'=|degC' '/(ksmn|adt|lm|cpu)0.temp0/ {printf("%2.1f", $2); exit}')"
                ;;
            esac
        ;;

        "Solaris")
            # Get CPU name.
            cpu="$(psrinfo -pv)"
            cpu="${cpu//*$'\n'}"
            cpu="${cpu/[0-9]\.*}"
            cpu="${cpu/ @*}"
            cpu="${cpu/\(portid*}"

            # Get CPU speed.
            speed="$(psrinfo -v | awk '/operates at/ {print $6; exit}')"

            # Get CPU cores.
            case $cpu_cores in
                "logical" | "on") cores="$(kstat -m cpu_info | grep -c -F "chip_id")" ;;
                "physical") cores="$(psrinfo -p)" ;;
            esac
        ;;

        "Haiku")
            # Get CPU name.
            cpu="$(sysinfo -cpu | awk -F '\\"' '/CPU #0/ {print $2}')"
            cpu="${cpu/@*}"

            # Get CPU speed.
            speed="$(sysinfo -cpu | awk '/running at/ {print $NF; exit}')"
            speed="${speed/MHz}"

            # Get CPU cores.
            cores="$(sysinfo -cpu | grep -c -F 'CPU #')"
        ;;

        "AIX")
            # Get CPU name.
            cpu="$(lsattr -El proc0 -a type | awk '{printf $2}')"

            # Get CPU speed.
            speed="$(prtconf -s | awk -F':' '{printf $2}')"
            speed="${speed/MHz}"

            # Get CPU cores.
            case $cpu_cores in
                "logical" | "on")
                    cores="$(lparstat -i | awk -F':' '/Online Virtual CPUs/ {printf $2}')"
                ;;

                "physical")
                    cores="$(lparstat -i | awk -F':' '/Active Physical CPUs/ {printf $2}')"
                ;;
            esac
        ;;

        "IRIX")
            # Get CPU name.
            cpu="$(hinv -c processor | awk -F':' '/CPU:/ {printf $2}')"

            # Get CPU speed.
            speed="$(hinv -c processor | awk '/MHZ/ {printf $2}')"

            # Get CPU cores.
            cores="$(sysconf NPROC_ONLN)"
        ;;

        "FreeMiNT")
            cpu="$(awk -F':' '/CPU:/ {printf $2}' /kern/cpuinfo)"
            speed="$(awk -F '[:.M]' '/Clocking:/ {printf $2}' /kern/cpuinfo)"
        ;;
    esac

    # Remove un-needed patterns from cpu output.
    cpu="${cpu//(TM)}"
    cpu="${cpu//(tm)}"
    cpu="${cpu//(R)}"
    cpu="${cpu//(r)}"
    cpu="${cpu//CPU}"
    cpu="${cpu//Processor}"
    cpu="${cpu//Dual-Core}"
    cpu="${cpu//Quad-Core}"
    cpu="${cpu//Six-Core}"
    cpu="${cpu//Eight-Core}"
    cpu="${cpu//[1-9][0-9]-Core}"
    cpu="${cpu//[0-9]-Core}"
    cpu="${cpu//, * Compute Cores}"
    cpu="${cpu//Core / }"
    cpu="${cpu//(\"AuthenticAMD\"*)}"
    cpu="${cpu//with Radeon * Graphics}"
    cpu="${cpu//, altivec supported}"
    cpu="${cpu//FPU*}"
    cpu="${cpu//Chip Revision*}"
    cpu="${cpu//Technologies, Inc}"
    cpu="${cpu//Core2/Core 2}"

    # Trim spaces from core and speed output
    cores="${cores//[[:space:]]}"
    speed="${speed//[[:space:]]}"

    # Remove CPU brand from the output.
    if [[ "$cpu_brand" == "off" ]]; then
        cpu="${cpu/AMD }"
        cpu="${cpu/Intel }"
        cpu="${cpu/Core? Duo }"
        cpu="${cpu/Qualcomm }"
    fi

    # Add CPU cores to the output.
    [[ "$cpu_cores" != "off" && "$cores" ]] && \
        case $os in
            "Mac OS X"|"macOS") cpu="${cpu/@/(${cores}) @}" ;;
            *)                  cpu="$cpu ($cores)" ;;
        esac

    # Add CPU speed to the output.
    if [[ "$cpu_speed" != "off" && "$speed" ]]; then
        if (( speed < 1000 )); then
            cpu="$cpu @ ${speed}MHz"
        else
            [[ "$speed_shorthand" == "on" ]] && speed="$((speed / 100))"
            speed="${speed:0:1}.${speed:1}"
            cpu="$cpu @ ${speed}GHz"
        fi
    fi

    # Add CPU temp to the output.
    if [[ "$cpu_temp" != "off" && "$deg" ]]; then
        deg="${deg//.}"

        # Convert to Fahrenheit if enabled
        [[ "$cpu_temp" == "F" ]] && deg="$((deg * 90 / 50 + 320))"

        # Format the output
        deg="[${deg/${deg: -1}}.${deg: -1}°${cpu_temp:-C}]"
        cpu="$cpu $deg"
    fi
}

