get_battery() {
    case $os in
        "Linux")
            # We use 'prin' here so that we can do multi battery support
            # with a single battery per line.
            for bat in "/sys/class/power_supply/"{BAT,axp288_fuel_gauge,CMB}*; do
                capacity="$(< "${bat}/capacity")"
                status="$(< "${bat}/status")"

                if [[ "$capacity" ]]; then
                    battery="${capacity}% [${status}]"

                    case $battery_display in
                        "bar")     battery="$(bar "$capacity" 100)" ;;
                        "infobar") battery+=" $(bar "$capacity" 100)" ;;
                        "barinfo") battery="$(bar "$capacity" 100)${info_color} ${battery}" ;;
                    esac

                    bat="${bat/*axp288_fuel_gauge}"
                    prin "${subtitle:+${subtitle}${bat: -1}}" "$battery"
                fi
            done
            return
        ;;

        "BSD")
            case $kernel_name in
                "FreeBSD"* | "DragonFly"*)
                    battery="$(acpiconf -i 0 | awk -F ':\t' '/Remaining capacity/ {print $2}')"
                    battery_state="$(acpiconf -i 0 | awk -F ':\t\t\t' '/State/ {print $2}')"
                ;;

                "NetBSD"*)
                    battery="$(envstat | awk '\\(|\\)' '/charge:/ {print $2}')"
                    battery="${battery/\.*/%}"
                ;;

                "OpenBSD"* | "Bitrig"*)
                    battery0full="$(sysctl -n   hw.sensors.acpibat0.watthour0\
                                                hw.sensors.acpibat0.amphour0)"
                    battery0full="${battery0full%% *}"

                    battery0now="$(sysctl -n    hw.sensors.acpibat0.watthour3\
                                                hw.sensors.acpibat0.amphour3)"
                    battery0now="${battery0now%% *}"

                    state="$(sysctl -n hw.sensors.acpibat0.raw0)"
                    state="${state##? (battery }"
                    state="${state%)*}"

                    [[ "${state}" == "charging" ]] && battery_state="charging"
                    [[ "$battery0full" ]] && \
                    battery="$((100 * ${battery0now/\.} / ${battery0full/\.}))%"
                ;;
            esac
        ;;

        "Mac OS X"|"macOS")
            battery="$(pmset -g batt | grep -o '[0-9]*%')"
            state="$(pmset -g batt | awk '/;/ {print $4}')"
            [[ "$state" == "charging;" ]] && battery_state="charging"
        ;;

        "Windows")
            battery="$(wmic Path Win32_Battery get EstimatedChargeRemaining)"
            battery="${battery/EstimatedChargeRemaining}"
            battery="$(trim "$battery")%"
            state="$(wmic /NameSpace:'\\root\WMI' Path BatteryStatus get Charging)"
            state="${state/Charging}"
            [[ "$state" == *TRUE* ]] && battery_state="charging"
        ;;

        "Haiku")
            battery0full="$(awk -F '[^0-9]*' 'NR==2 {print $4}' /dev/power/acpi_battery/0)"
            battery0now="$(awk -F '[^0-9]*' 'NR==5 {print $4}' /dev/power/acpi_battery/0)"
            battery="$((battery0full * 100 / battery0now))%"
        ;;
    esac

    [[ "$battery_state" ]] && battery+=" Charging"

    case $battery_display in
        "bar")     battery="$(bar "${battery/\%*}" 100)" ;;
        "infobar") battery="${battery} $(bar "${battery/\%*}" 100)" ;;
        "barinfo") battery="$(bar "${battery/\%*}" 100)${info_color} ${battery}" ;;
    esac
}

