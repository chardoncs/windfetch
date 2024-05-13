get_wm_theme() {
    ((wm_run != 1)) && get_wm
    ((de_run != 1)) && get_de

    case $wm  in
        E16)
            wm_theme=$(awk -F "= " '/theme.name/ {print $2}' "${HOME}/.e16/e_config--0.0.cfg")
        ;;

        Sawfish)
            wm_theme=$(awk -F '\\(quote|\\)' '/default-frame-style/ {print $(NF-4)}' \
                       "$HOME/.sawfish/custom")
        ;;

        Cinnamon|Muffin|"Mutter (Muffin)")
            detheme=$(gsettings get org.cinnamon.theme name)
            wm_theme=$(gsettings get org.cinnamon.desktop.wm.preferences theme)
            wm_theme="$detheme ($wm_theme)"
        ;;

        Compiz|Mutter|Gala)
            if type -p gsettings >/dev/null; then
                wm_theme=$(gsettings get org.gnome.shell.extensions.user-theme name)

                [[ ${wm_theme//\'} ]] || \
                    wm_theme=$(gsettings get org.gnome.desktop.wm.preferences theme)

            elif type -p gconftool-2 >/dev/null; then
                wm_theme=$(gconftool-2 -g /apps/metacity/general/theme)
            fi
        ;;

        Metacity*)
            if [[ $de == Deepin ]]; then
                wm_theme=$(gsettings get com.deepin.wrap.gnome.desktop.wm.preferences theme)

            elif [[ $de == MATE ]]; then
                wm_theme=$(gsettings get org.mate.Marco.general theme)

            else
                wm_theme=$(gconftool-2 -g /apps/metacity/general/theme)
            fi
        ;;

        E17|Enlightenment)
            if type -p eet >/dev/null; then
                wm_theme=$(eet -d "$HOME/.e/e/config/standard/e.cfg" config |\
                            awk '/value \"file\" string.*.edj/ {print $4}')
                wm_theme=${wm_theme##*/}
                wm_theme=${wm_theme%.*}
            fi
        ;;

        Fluxbox)
            [[ -f $HOME/.fluxbox/init ]] &&
                wm_theme=$(awk -F "/" '/styleFile/ {print $NF}' "$HOME/.fluxbox/init")
        ;;

        IceWM*)
            [[ -f $HOME/.icewm/theme ]] &&
                wm_theme=$(awk -F "[\",/]" '!/#/ {print $2}' "$HOME/.icewm/theme")
        ;;

        Openbox)
            case $de in
                LXDE*) ob_file=lxde-rc ;;
                LXQt*) ob_file=lxqt-rc ;;
                    *) ob_file=rc ;;
            esac

            ob_file=$XDG_CONFIG_HOME/openbox/$ob_file.xml

            [[ -f $ob_file ]] &&
                wm_theme=$(awk '/<theme>/ {while (getline n) {if (match(n, /<name>/))
                            {l=n; exit}}} END {split(l, a, "[<>]"); print a[3]}' "$ob_file")
        ;;

        PekWM)
            [[ -f $HOME/.pekwm/config ]] &&
                wm_theme=$(awk -F "/" '/Theme/{gsub(/\"/,""); print $NF}' "$HOME/.pekwm/config")
        ;;

        Xfwm4)
            [[ -f $HOME/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml ]] &&
                wm_theme=$(xfconf-query -c xfwm4 -p /general/theme)
        ;;

        KWin*)
            kde_config_dir
            kwinrc=$kde_config_dir/kwinrc
            kdebugrc=$kde_config_dir/kdebugrc

            if [[ -f $kwinrc ]]; then
                wm_theme=$(awk '/theme=/ {
                                    gsub(/theme=.*qml_|theme=.*svg__/,"",$0);
                                    print $0;
                                    exit
                                 }' "$kwinrc")

                [[ "$wm_theme" ]] ||
                    wm_theme=$(awk '/library=org.kde/ {
                                        gsub(/library=org.kde./,"",$0);
                                        print $0;
                                        exit
                                     }' "$kwinrc")

                [[ $wm_theme ]] ||
                    wm_theme=$(awk '/PluginLib=kwin3_/ {
                                        gsub(/PluginLib=kwin3_/,"",$0);
                                        print $0;
                                        exit
                                     }' "$kwinrc")

            elif [[ -f $kdebugrc ]]; then
                wm_theme=$(awk '/(decoration)/ {gsub(/\[/,"",$1); print $1; exit}' "$kdebugrc")
            fi

            wm_theme=${wm_theme/theme=}
        ;;

        "Quartz Compositor")
            global_preferences=$HOME/Library/Preferences/.GlobalPreferences.plist
            wm_theme=$(PlistBuddy -c "Print AppleInterfaceStyle" "$global_preferences")
            wm_theme_color=$(PlistBuddy -c "Print AppleAccentColor" "$global_preferences")

            [[ "$wm_theme" ]] ||
                wm_theme=Light

            case $wm_theme_color in
                -1) wm_theme_color=Graphite ;;
                0)  wm_theme_color=Red ;;
                1)  wm_theme_color=Orange ;;
                2)  wm_theme_color=Yellow ;;
                3)  wm_theme_color=Green ;;
                5)  wm_theme_color=Purple ;;
                6)  wm_theme_color=Pink ;;
                *)  wm_theme_color=Blue ;;
            esac

            wm_theme="$wm_theme_color ($wm_theme)"
        ;;

        *Explorer)
            path=/proc/registry/HKEY_CURRENT_USER/Software/Microsoft
            path+=/Windows/CurrentVersion/Themes/CurrentTheme

            wm_theme=$(head -n1 "$path")
            wm_theme=${wm_theme##*\\}
            wm_theme=${wm_theme%.*}
        ;;

        Blackbox|bbLean*)
            path=$(wmic process get ExecutablePath | grep -F "blackbox")
            path=${path//\\/\/}

            wm_theme=$(grep '^session\.styleFile:' "${path/\.exe/.rc}")
            wm_theme=${wm_theme/session\.styleFile: }
            wm_theme=${wm_theme##*\\}
            wm_theme=${wm_theme%.*}
        ;;
    esac

    wm_theme=$(trim_quotes "$wm_theme")
}

