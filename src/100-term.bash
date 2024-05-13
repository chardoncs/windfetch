get_term() {
    # If function was run, stop here.
    ((term_run == 1)) && return

    # Workaround for macOS systems that
    # don't support the block below.
    case $TERM_PROGRAM in
        "iTerm.app")    term="iTerm2" ;;
        "Terminal.app") term="Apple Terminal" ;;
        "Hyper")        term="HyperTerm" ;;
        *)              term="${TERM_PROGRAM/\.app}" ;;
    esac

    # Most likely TosWin2 on FreeMiNT - quick check
    [[ "$TERM" == "tw52" || "$TERM" == "tw100" ]] && term="TosWin2"
    [[ "$SSH_CONNECTION" ]] && term="$SSH_TTY"
    [[ "$WT_SESSION" ]]     && term="Windows Terminal"

    # Check $PPID for terminal emulator.
    while [[ -z "$term" ]]; do
        parent="$(get_ppid "$parent")"
        [[ -z "$parent" ]] && break
        name="$(get_process_name "$parent")"

        case ${name// } in
            "${SHELL/*\/}"|*"sh"|"screen"|"su"*|"newgrp") ;;

            "login"*|*"Login"*|"init"|"(init)")
                term="$(tty)"
            ;;

            "ruby"|"1"|"tmux"*|"systemd"|"sshd"*|"python"*|\
            "USER"*"PID"*|"kdeinit"*|"launchd"*|"bwrap")
                break
            ;;

            "gnome-terminal-") term="gnome-terminal" ;;
            "urxvtd")          term="urxvt" ;;
            *"nvim")           term="Neovim Terminal" ;;
            *"NeoVimServer"*)  term="VimR Terminal" ;;

            *)
                # Fix issues with long process names on Linux.
                [[ $os == Linux ]] && term=$(realpath "/proc/$parent/exe")

                term="${name##*/}"

                # Fix wrapper names in Nix.
                [[ $term == .*-wrapped ]] && {
                   term="${term#.}"
                   term="${term%-wrapped}"
                }
            ;;
        esac
    done

    # Log that the function was run.
    term_run=1
}

get_term_font() {
    ((term_run != 1)) && get_term

    case $term in
        "alacritty"*)
            shopt -s nullglob
            confs=({$XDG_CONFIG_HOME,$HOME}/{alacritty,}/{.,}alacritty.ym?)
            shopt -u nullglob

            [[ -f "${confs[0]}" ]] || return

            term_font="$(awk '/normal:/ {while (!/family:/ || /#/)
                         {if (!getline) {exit}} print; exit}' "${confs[0]}")"
            term_font="${term_font/*family:}"
            term_font="${term_font/$'\n'*}"
            term_font="${term_font/\#*}"
            term_font="${term_font//\"}"
        ;;

        "Apple_Terminal")
            term_font="$(osascript <<END
                         tell application "Terminal" to font name of window frontmost
END
)"
        ;;

        "iTerm2")
            # Unfortunately the profile name is not unique, but it seems to be the only thing
            # that identifies an active profile. There is the "id of current session of current win-
            # dow" though, but that does not match to a guid in the plist.
            # So, be warned, collisions may occur!
            # See: https://groups.google.com/forum/#!topic/iterm2-discuss/0tO3xZ4Zlwg
            local current_profile_name profiles_count profile_name diff_font

            current_profile_name="$(osascript <<END
                                    tell application "iTerm2" to profile name \
                                    of current session of current window
END
)"

            # Warning: Dynamic profiles are not taken into account here!
            # https://www.iterm2.com/documentation-dynamic-profiles.html
            font_file="${HOME}/Library/Preferences/com.googlecode.iterm2.plist"

            # Count Guids in "New Bookmarks"; they should be unique
            profiles_count="$(PlistBuddy -c "Print ':New Bookmarks:'" "$font_file" | \
                              grep -w -c "Guid")"

            for ((i=0; i<profiles_count; i++)); do
                profile_name="$(PlistBuddy -c "Print ':New Bookmarks:${i}:Name:'" "$font_file")"

                if [[ "$profile_name" == "$current_profile_name" ]]; then
                    # "Normal Font"
                    term_font="$(PlistBuddy -c "Print ':New Bookmarks:${i}:Normal Font:'" \
                                 "$font_file")"

                    # Font for non-ascii characters
                    # Only check for a different non-ascii font, if the user checked
                    # the "use a different font for non-ascii text" switch.
                    diff_font="$(PlistBuddy -c "Print ':New Bookmarks:${i}:Use Non-ASCII Font:'" \
                                 "$font_file")"

                    if [[ "$diff_font" == "true" ]]; then
                        non_ascii="$(PlistBuddy -c "Print ':New Bookmarks:${i}:Non Ascii Font:'" \
                                     "$font_file")"

                        [[ "$term_font" != "$non_ascii" ]] && \
                            term_font="$term_font (normal) / $non_ascii (non-ascii)"
                    fi
                fi
            done
        ;;

        "deepin-terminal"*)
            term_font="$(awk -F '=' '/font=/ {a=$2} /font_size/ {b=$2} END {print a,b}' \
                         "${XDG_CONFIG_HOME}/deepin/deepin-terminal/config.conf")"
        ;;

        "GNUstep_Terminal")
             term_font="$(awk -F '>|<' '/>TerminalFont</ {getline; f=$3}
                          />TerminalFontSize</ {getline; s=$3} END {print f,s}' \
                          "${HOME}/GNUstep/Defaults/Terminal.plist")"
        ;;

        "Hyper"*)
            term_font="$(awk -F':|,' '/fontFamily/ {print $2; exit}' "${HOME}/.hyper.js")"
            term_font="$(trim_quotes "$term_font")"
        ;;

        "kitty"*)
            term_font="from kitty.cli import *; o = create_default_opts(); \
                       print(f'{o.font_family} {o.font_size}')"
            term_font="$(kitty +runpy ''"$term_font"'')"
        ;;

        "konsole" | "yakuake")
            # Get Process ID of current konsole window / tab
            child="$(get_ppid "$$")"

            QT_BINDIR="$(qtpaths --binaries-dir)" && PATH+=":$QT_BINDIR"

            IFS=$'\n' read -d "" -ra konsole_instances \
                <<< "$(qdbus | awk '/org.kde.'"$term"'/ {print $1}')"

            for i in "${konsole_instances[@]}"; do
                IFS=$'\n' read -d "" -ra konsole_sessions <<< "$(qdbus "$i" | grep -F '/Sessions/')"

                for session in "${konsole_sessions[@]}"; do
                    if ((child == "$(qdbus "$i" "$session" processId)")); then
                        profile="$(qdbus "$i" "$session" environment |\
                                   awk -F '=' '/KONSOLE_PROFILE_NAME/ {print $2}')"
                        [[ $profile ]] || profile="$(qdbus "$i" "$session" profile)"
                        break
                    fi
                done
                [[ $profile ]] && break
            done

            [[ $profile ]] || return

            # We could have two profile files for the same profile name, take first match
            profile_filename="$(grep -l "Name=${profile}" "$HOME"/.local/share/konsole/*.profile)"
            profile_filename="${profile_filename/$'\n'*}"

            [[ $profile_filename ]] && \
                term_font="$(awk -F '=|,' '/Font=/ {print $2,$3}' "$profile_filename")"
        ;;

        "lxterminal"*)
            term_font="$(awk -F '=' '/fontname=/ {print $2; exit}' \
                         "${XDG_CONFIG_HOME}/lxterminal/lxterminal.conf")"
        ;;

        "mate-terminal")
            # To get the actual config we have to create a temporarily file with the
            # --save-config option.
            mateterm_config="/tmp/mateterm.cfg"

            # Ensure /tmp exists and we do not overwrite anything.
            if [[ -d "/tmp" && ! -f "$mateterm_config" ]]; then
                mate-terminal --save-config="$mateterm_config"

                role="$(xprop -id "${WINDOWID}" WM_WINDOW_ROLE)"
                role="${role##* }"
                role="${role//\"}"

                profile="$(awk -F '=' -v r="$role" \
                                  '$0~r {
                                            getline;
                                            if(/Maximized/) getline;
                                            if(/Fullscreen/) getline;
                                            id=$2"]"
                                         } $0~id {if(id) {getline; print $2; exit}}' \
                           "$mateterm_config")"

                rm -f "$mateterm_config"

                mate_get() {
                   gsettings get org.mate.terminal.profile:/org/mate/terminal/profiles/"$1"/ "$2"
                }

                if [[ "$(mate_get "$profile" "use-system-font")" == "true" ]]; then
                    term_font="$(gsettings get org.mate.interface monospace-font-name)"
                else
                    term_font="$(mate_get "$profile" "font")"
                fi
                term_font="$(trim_quotes "$term_font")"
            fi
        ;;

        "mintty")
            term_font="$(awk -F '=' '!/^($|#)/ && /^\\s*Font\\s*=/ {printf $2; exit}' "${HOME}/.minttyrc")"
        ;;

        "pantheon"*)
            term_font="$(gsettings get org.pantheon.terminal.settings font)"

            [[ -z "${term_font//\'}" ]] && \
                term_font="$(gsettings get org.gnome.desktop.interface monospace-font-name)"

            term_font="$(trim_quotes "$term_font")"
        ;;

        "qterminal")
            term_font="$(awk -F '=' '/fontFamily=/ {a=$2} /fontSize=/ {b=$2} END {print a,b}' \
                         "${XDG_CONFIG_HOME}/qterminal.org/qterminal.ini")"
        ;;

        "sakura"*)
            term_font="$(awk -F '=' '/^font=/ {print $2; exit}' \
                         "${XDG_CONFIG_HOME}/sakura/sakura.conf")"
        ;;

        "st")
            term_font="$(ps -o command= -p "$parent" | grep -F -- "-f")"

            if [[ "$term_font" ]]; then
                term_font="${term_font/*-f/}"
                term_font="${term_font/ -*/}"

            else
                # On Linux we can get the exact path to the running binary through the procfs
                # (in case `st` is launched from outside of $PATH) on other systems we just
                # have to guess and assume `st` is invoked from somewhere in the users $PATH
                [[ -L "/proc/$parent/exe" ]] && binary="/proc/$parent/exe" || binary="$(type -p st)"

                # Grep the output of strings on the `st` binary for anything that looks vaguely
                # like a font definition. NOTE: There is a slight limitation in this approach.
                # Technically "Font Name" is a valid font. As it doesn't specify any font options
                # though it is hard to match it correctly amongst the rest of the noise.
                [[ -n "$binary" ]] &&
                    term_font=$(
                        strings "$binary" |

                        grep -m 1 "*font[^2]"
                    )
            fi

            term_font="${term_font/xft:}"
            term_font="${term_font#*=}"
            term_font="${term_font/:*}"
        ;;

        "terminology")
            term_font="$(strings "${XDG_CONFIG_HOME}/terminology/config/standard/base.cfg" |\
                         awk '/^font\.name$/{print a}{a=$0}')"
            term_font="${term_font/.pcf}"
            term_font="${term_font/:*}"
        ;;

        "termite")
            [[ -f "${XDG_CONFIG_HOME}/termite/config" ]] && \
                termite_config="${XDG_CONFIG_HOME}/termite/config"

            term_font="$(awk -F '= ' '/\[options\]/ {
                                          opt=1
                                      }
                                      /^\s*font/ {
                                          if(opt==1) a=$2;
                                          opt=0
                                      } END {print a}' "/etc/xdg/termite/config" \
                         "$termite_config")"
        ;;

        urxvt|urxvtd|rxvt-unicode|xterm)
            xrdb=$(xrdb -query)
            term_font=$(grep -im 1 -e "^${term/d}"'\**\.*font:' -e '^\*font:' <<< "$xrdb")
            term_font=${term_font/*"*font:"}
            term_font=${term_font/*".font:"}
            term_font=${term_font/*"*.font:"}
            term_font=$(trim "$term_font")

            [[ -z $term_font && $term == xterm ]] && \
                term_font=$(grep '^XTerm.vt100.faceName' <<< "$xrdb")

            term_font=$(trim "${term_font/*"faceName:"}")

            # xft: isn't required at the beginning so we prepend it if it's missing
            [[ ${term_font:0:1} != '-' && ${term_font:0:4} != xft: ]] && \
                term_font=xft:$term_font

            # Xresources has two different font formats, this checks which
            # one is in use and formats it accordingly.
            case $term_font in
                *xft:*)
                    term_font=${term_font/xft:}
                    term_font=${term_font/:*}
                ;;

                -*)
                    IFS=- read -r _ _ term_font _ <<< "$term_font"
                ;;
            esac
        ;;

        "xfce4-terminal")
            term_font="$(awk -F '=' '/^FontName/{a=$2}/^FontUseSystem=TRUE/{a=$0} END {print a}' \
                         "${XDG_CONFIG_HOME}/xfce4/terminal/terminalrc")"

            [[ "$term_font" == "FontUseSystem=TRUE" ]] && \
                term_font="$(gsettings get org.gnome.desktop.interface monospace-font-name)"

            term_font="$(trim_quotes "$term_font")"

            # Default fallback font hardcoded in terminal-preferences.c
            [[ -z "$term_font" ]] && term_font="Monospace 12"
        ;;

        conemu-*)
            # Could have used `eval set -- "$ConEmuArgs"` instead for arg parsing.
            readarray -t ce_arg_list < <(xargs -n1 printf "%s\n" <<< "${ConEmuArgs-}")

            for ce_arg_idx in "${!ce_arg_list[@]}"; do
                # Search for "-LoadCfgFile" arg
                [[ "${ce_arg_list[$ce_arg_idx]}" == -LoadCfgFile ]] && {
                    # Conf path is the next arg
                    ce_conf=${ce_arg_list[++ce_arg_idx]}
                    break
                }
            done

            # https://conemu.github.io/en/ConEmuXml.html#search-sequence
            for ce_conf in "$ce_conf" "${ConEmuDir-}\ConEmu.xml" "${ConEmuDir-}\.ConEmu.xml" \
                           "${ConEmuBaseDir-}\ConEmu.xml" "${ConEmuBaseDir-}\.ConEmu.xml" \
                           "$APPDATA\ConEmu.xml" "$APPDATA\.ConEmu.xml"; do
                # Search for first conf file available
                [[ -f "$ce_conf" ]] && {
                    # Very basic XML parsing
                    term_font="$(awk '/name="FontName"/ && match($0, /data="([^"]*)"/) {
                        print substr($0, RSTART+6, RLENGTH-7)}' "$ce_conf")"
                    break
                }
            done

            # Null-terminated contents in /proc/registry files triggers a Bash warning.
            [[ "$term_font" ]] || read -r term_font < \
                /proc/registry/HKEY_CURRENT_USER/Software/ConEmu/.Vanilla/FontName
        ;;
    esac
}

