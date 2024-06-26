get_song() {
    players=(
        "amarok"
        "audacious"
        "banshee"
        "bluemindo"
        "clementine"
        "cmus"
        "deadbeef"
        "deepin-music"
        "dragon"
        "elisa"
        "exaile"
        "gnome-music"
        "gmusicbrowser"
        "gogglesmm"
        "guayadeque"
        "io.elementary.music"
        "iTunes"
        "Music"
        "juk"
        "lollypop"
        "MellowPlayer"
        "mocp"
        "mopidy"
        "mpd"
        "muine"
        "netease-cloud-music"
        "olivia"
        "plasma-browser-integration"
        "playerctl"
        "pogo"
        "pragha"
        "qmmp"
        "quodlibet"
        "rhythmbox"
        "sayonara"
        "smplayer"
        "spotify"
        "Spotify"
        "strawberry"
        "tauonmb"
        "tomahawk"
        "vlc"
        "xmms2d"
        "xnoise"
        "yarock"
    )

    printf -v players "|%s" "${players[@]}"
    player="$(ps aux | awk -v pattern="(${players:1})" \
        '!/ awk / && !/iTunesHelper/ && match($0,pattern){print substr($0,RSTART,RLENGTH); exit}')"

    [[ "$music_player" && "$music_player" != "auto" ]] && player="$music_player"

    get_song_dbus() {
        # Multiple players use an almost identical dbus command to get the information.
        # This function saves us using the same command throughout the function.
        song="$(\
            dbus-send --print-reply --dest=org.mpris.MediaPlayer2."${1}" /org/mpris/MediaPlayer2 \
            org.freedesktop.DBus.Properties.Get string:'org.mpris.MediaPlayer2.Player' \
            string:'Metadata' |\
            awk -F '"' 'BEGIN {RS=" entry"}; /"xesam:artist"/ {a = $4} /"xesam:album"/ {b = $4}
                        /"xesam:title"/ {t = $4} END {print a " \n" b " \n" t}'
        )"
    }

    case ${player/*\/} in
        "mocp"*)          song="$(mocp -Q '%artist \n%album \n%song')" ;;
        "deadbeef"*)      song="$(deadbeef --nowplaying-tf '%artist% \\n%album% \\n%title%')" ;;
        "qmmp"*)          song="$(qmmp --nowplaying '%p \n%a \n%t')" ;;
        "gnome-music"*)   get_song_dbus "GnomeMusic" ;;
        "lollypop"*)      get_song_dbus "Lollypop" ;;
        "clementine"*)    get_song_dbus "clementine" ;;
        "cmus"*)          get_song_dbus "cmus" ;;
        "juk"*)           get_song_dbus "juk" ;;
        "bluemindo"*)     get_song_dbus "Bluemindo" ;;
        "guayadeque"*)    get_song_dbus "guayadeque" ;;
        "yarock"*)        get_song_dbus "yarock" ;;
        "deepin-music"*)  get_song_dbus "DeepinMusic" ;;
        "tomahawk"*)      get_song_dbus "tomahawk" ;;
        "elisa"*)         get_song_dbus "elisa" ;;
        "sayonara"*)      get_song_dbus "sayonara" ;;
        "audacious"*)     get_song_dbus "audacious" ;;
        "vlc"*)           get_song_dbus "vlc" ;;
        "gmusicbrowser"*) get_song_dbus "gmusicbrowser" ;;
        "pragha"*)        get_song_dbus "pragha" ;;
        "amarok"*)        get_song_dbus "amarok" ;;
        "dragon"*)        get_song_dbus "dragonplayer" ;;
        "smplayer"*)      get_song_dbus "smplayer" ;;
        "rhythmbox"*)     get_song_dbus "rhythmbox" ;;
        "strawberry"*)    get_song_dbus "strawberry" ;;
        "gogglesmm"*)     get_song_dbus "gogglesmm" ;;
        "xnoise"*)        get_song_dbus "xnoise" ;;
        "tauonmb"*)       get_song_dbus "tauon" ;;
        "olivia"*)        get_song_dbus "olivia" ;;
        "exaile"*)        get_song_dbus "exaile" ;;
        "netease-cloud-music"*)        get_song_dbus "netease-cloud-music" ;;
        "plasma-browser-integration"*) get_song_dbus "plasma-browser-integration" ;;
        "io.elementary.music"*)        get_song_dbus "Music" ;;
        "MellowPlayer"*)  get_song_dbus "MellowPlayer3" ;;

        "mpd"* | "mopidy"*)
            song="$(mpc -f '%artist% \n%album% \n%title%' current "${mpc_args[@]}")"
        ;;

        "xmms2d"*)
            song="$(xmms2 current -f "\${artist}"$' \n'"\${album}"$' \n'"\${title}")"
        ;;

        "spotify"*)
            case $os in
                "Linux") get_song_dbus "spotify" ;;

                "Mac OS X"|"macOS")
                    song="$(osascript -e 'tell application "Spotify" to artist of current track as¬
                                          string & "\n" & album of current track as¬
                                          string & "\n" & name of current track as string')"
                ;;
            esac
        ;;

        "itunes"*)
            song="$(osascript -e 'tell application "iTunes" to artist of current track as¬
                                  string & "\n" & album of current track as¬
                                  string & "\n" & name of current track as string')"
        ;;

        "music"*)
            song="$(osascript -e 'tell application "Music" to artist of current track as¬
                                  string & "\n" & album of current track as¬
                                  string & "\n" & name of current track as string')"
        ;;

        "banshee"*)
            song="$(banshee --query-artist --query-album --query-title |\
                    awk -F':' '/^artist/ {a=$2} /^album/ {b=$2} /^title/ {t=$2}
                               END {print a " \n" b " \n"t}')"
        ;;

        "muine"*)
            song="$(dbus-send --print-reply --dest=org.gnome.Muine /org/gnome/Muine/Player \
                    org.gnome.Muine.Player.GetCurrentSong |
                    awk -F':' '/^artist/ {a=$2} /^album/ {b=$2} /^title/ {t=$2}
                               END {print a " \n" b " \n" t}')"
        ;;

        "quodlibet"*)
            song="$(dbus-send --print-reply --dest=net.sacredchao.QuodLibet \
                    /net/sacredchao/QuodLibet net.sacredchao.QuodLibet.CurrentSong |\
                    awk -F'"' 'BEGIN {RS=" entry"}; /"artist"/ {a=$4} /"album"/ {b=$4}
                    /"title"/ {t=$4} END {print a " \n" b " \n" t}')"
        ;;

        "pogo"*)
            song="$(dbus-send --print-reply --dest=org.mpris.pogo /Player \
                    org.freedesktop.MediaPlayer.GetMetadata |
                    awk -F'"' 'BEGIN {RS=" entry"}; /"artist"/ {a=$4} /"album"/ {b=$4}
                    /"title"/ {t=$4} END {print a " \n" b " \n" t}')"
        ;;

        "playerctl"*)
            song="$(playerctl metadata --format '{{ artist }} \n{{ album }} \n{{ title }}')"
         ;;

        *) mpc &>/dev/null && song="$(mpc -f '%artist% \n%album% \n%title%' current)" || return ;;
    esac

    IFS=$'\n' read -d "" -r artist album title <<< "${song//'\n'/$'\n'}"

    # Make sure empty tags are truly empty.
    artist="$(trim "$artist")"
    album="$(trim "$album")"
    title="$(trim "$title")"

    # Set default values if no tags were found.
    : "${artist:=Unknown Artist}" "${album:=Unknown Album}" "${title:=Unknown Song}"

    # Display Artist, Album and Title on separate lines.
    if [[ "$song_shorthand" == "on" ]]; then
        prin "Artist" "$artist"
        prin "Album"  "$album"
        prin "Song"   "$title"
    else
        song="${song_format/\%artist\%/$artist}"
        song="${song/\%album\%/$album}"
        song="${song/\%title\%/$title}"
    fi
}

