get_style() {
    # Fix weird output when the function is run multiple times.
    unset gtk2_theme gtk3_theme theme path

    if [[ "$DISPLAY" && $os != "Mac OS X" && $os != "macOS" ]]; then
        # Get DE if user has disabled the function.
        ((de_run != 1)) && get_de

        # Remove version from '$de'.
        [[ $de_version == on ]] && de=${de/ *}

        # Check for DE Theme.
        case $de in
            "KDE"* | "Plasma"*)
                kde_config_dir

                if [[ -f "${kde_config_dir}/kdeglobals" ]]; then
                    kde_config_file="${kde_config_dir}/kdeglobals"

                    kde_theme="$(grep "^${kde}" "$kde_config_file")"
                    kde_theme="${kde_theme/*=}"
                    if [[ "$kde" == "font" ]]; then
                        kde_font_size="${kde_theme#*,}"
                        kde_font_size="${kde_font_size/,*}"
                        kde_theme="${kde_theme/,*} ${kde_theme/*,} ${kde_font_size}"
                    fi
                    kde_theme="$kde_theme [$de], "
                else
                    err "Theme: KDE config files not found, skipping."
                fi
            ;;

            *"Cinnamon"*)
                if type -p gsettings >/dev/null; then
                    gtk3_theme="$(gsettings get org.cinnamon.desktop.interface "$gsettings")"
                    gtk2_theme="$gtk3_theme"
                fi
            ;;

            "Gnome"* | "Unity"* | "Budgie"*)
                if type -p gsettings >/dev/null; then
                    gtk3_theme="$(gsettings get org.gnome.desktop.interface "$gsettings")"
                    gtk2_theme="$gtk3_theme"

                elif type -p gconftool-2 >/dev/null; then
                    gtk2_theme="$(gconftool-2 -g /desktop/gnome/interface/"$gconf")"
                fi
            ;;

            "Mate"*)
                gtk3_theme="$(gsettings get org.mate.interface "$gsettings")"
                gtk2_theme="$gtk3_theme"
            ;;

            "Xfce"*)
                type -p xfconf-query >/dev/null && \
                    gtk2_theme="$(xfconf-query -c xsettings -p "$xfconf")"
            ;;
        esac

        # Check for general GTK2 Theme.
        if [[ -z "$gtk2_theme" ]]; then
            if [[ -n "$GTK2_RC_FILES" ]]; then
                IFS=: read -ra rc_files <<< "$GTK2_RC_FILES"
                gtk2_theme="$(grep "^[^#]*${name}" "${rc_files[@]}")"
            elif [[ -f "${HOME}/.gtkrc-2.0"  ]]; then
                gtk2_theme="$(grep "^[^#]*${name}" "${HOME}/.gtkrc-2.0")"

            elif [[ -f "/etc/gtk-2.0/gtkrc" ]]; then
                gtk2_theme="$(grep "^[^#]*${name}" /etc/gtk-2.0/gtkrc)"

            elif [[ -f "/usr/share/gtk-2.0/gtkrc" ]]; then
                gtk2_theme="$(grep "^[^#]*${name}" /usr/share/gtk-2.0/gtkrc)"

            fi

            gtk2_theme="${gtk2_theme/*${name}*=}"
        fi

        # Check for general GTK3 Theme.
        if [[ -z "$gtk3_theme" ]]; then
            if [[ -f "${XDG_CONFIG_HOME}/gtk-3.0/settings.ini" ]]; then
                gtk3_theme="$(grep "^[^#]*$name" "${XDG_CONFIG_HOME}/gtk-3.0/settings.ini")"

            elif type -p gsettings >/dev/null; then
                gtk3_theme="$(gsettings get org.gnome.desktop.interface "$gsettings")"

            elif [[ -f "/etc/gtk-3.0/settings.ini" ]]; then
                gtk3_theme="$(grep "^[^#]*$name" /etc/gtk-3.0/settings.ini)"

            elif [[ -f "/usr/share/gtk-3.0/settings.ini" ]]; then
                gtk3_theme="$(grep "^[^#]*$name" /usr/share/gtk-3.0/settings.ini)"
            fi

            gtk3_theme="${gtk3_theme/${name}*=}"
        fi

        # Trim whitespace.
        gtk2_theme="$(trim "$gtk2_theme")"
        gtk3_theme="$(trim "$gtk3_theme")"

        # Remove quotes.
        gtk2_theme="$(trim_quotes "$gtk2_theme")"
        gtk3_theme="$(trim_quotes "$gtk3_theme")"

        # Toggle visibility of GTK themes.
        [[ "$gtk2" == "off" ]] && unset gtk2_theme
        [[ "$gtk3" == "off" ]] && unset gtk3_theme

        # Format the string based on which themes exist.
        if [[ "$gtk2_theme" && "$gtk2_theme" == "$gtk3_theme" ]]; then
            gtk3_theme+=" [GTK2/3]"
            unset gtk2_theme

        elif [[ "$gtk2_theme" && "$gtk3_theme" ]]; then
            gtk2_theme+=" [GTK2], "
            gtk3_theme+=" [GTK3] "

        else
            [[ "$gtk2_theme" ]] && gtk2_theme+=" [GTK2] "
            [[ "$gtk3_theme" ]] && gtk3_theme+=" [GTK3] "
        fi

        # Final string.
        theme="${kde_theme}${gtk2_theme}${gtk3_theme}"
        theme="${theme%, }"

        # Make the output shorter by removing "[GTKX]" from the string.
        if [[ "$gtk_shorthand" == "on" ]]; then
            theme="${theme// '[GTK'[0-9]']'}"
            theme="${theme/ '[GTK2/3]'}"
            theme="${theme/ '[KDE]'}"
            theme="${theme/ '[Plasma]'}"
        fi
    fi
}

get_theme() {
    name="gtk-theme-name"
    gsettings="gtk-theme"
    gconf="gtk_theme"
    xfconf="/Net/ThemeName"
    kde="Name"

    get_style
}

get_icons() {
    name="gtk-icon-theme-name"
    gsettings="icon-theme"
    gconf="icon_theme"
    xfconf="/Net/IconThemeName"
    kde="Theme"

    get_style
    icons="$theme"
}

get_font() {
    name="gtk-font-name"
    gsettings="font-name"
    gconf="font_theme"
    xfconf="/Gtk/FontName"
    kde="font"

    get_style
    font="$theme"
}

