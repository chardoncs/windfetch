# IMAGES

image_backend() {
    [[ "$image_backend" != "off" ]] && ! type -p convert &>/dev/null && \
        { image_backend="ascii"; err "Image: Imagemagick not found, falling back to ascii mode."; }

    case ${image_backend:-off} in
        "ascii") print_ascii ;;
        "off") image_backend="off" ;;

        "caca" | "catimg" | "chafa" | "jp2a" | "iterm2" | "termpix" |\
        "tycat" | "w3m" | "sixel" | "pixterm" | "kitty" | "pot", | "ueberzug" |\
         "viu")
            get_image_source

            [[ ! -f "$image" ]] && {
                to_ascii "Image: '$image_source' doesn't exist, falling back to ascii mode."
                return
            }
            [[ "$image_backend" == "ueberzug" ]] && wait=true;

            get_window_size

            ((term_width < 1)) && {
                to_ascii "Image: Failed to find terminal window size."
                err "Image: Check the 'Images in the terminal' wiki page for more info,"
                return
            }

            printf '\e[2J\e[H'
            get_image_size
            make_thumbnail
            display_image || to_off "Image: $image_backend failed to display the image."
        ;;

        *)
            err "Image: Unknown image backend specified '$image_backend'."
            err "Image: Valid backends are: 'ascii', 'caca', 'catimg', 'chafa', 'jp2a', 'iterm2',
                                            'kitty', 'off', 'sixel', 'pot', 'pixterm', 'termpix',
                                            'tycat', 'w3m', 'viu')"
            err "Image: Falling back to ascii mode."
            print_ascii
        ;;
    esac

    # Set cursor position next image/ascii.
    [[ "$image_backend" != "off" ]] && printf '\e[%sA\e[9999999D' "${lines:-0}"
}

print_ascii() {
    if [[ -f "$image_source" && ! "$image_source" =~ (png|jpg|jpeg|jpe|svg|gif) ]]; then
        ascii_data="$(< "$image_source")"
    elif [[ "$image_source" == "ascii" || $image_source == auto ]]; then
        :
    else
        ascii_data="$image_source"
    fi

    # Set locale to get correct padding.
    LC_ALL="$sys_locale"

    # Calculate size of ascii file in line length / line count.
    while IFS=$'\n' read -r line; do
        line=${line//\\\\/\\}
        line=${line//█/ }
        ((++lines,${#line}>ascii_len)) && ascii_len="${#line}"
    done <<< "${ascii_data//\$\{??\}}"

    # Fallback if file not found.
    ((lines==1)) && {
        lines=
        ascii_len=
        image_source=auto
        get_distro_ascii
        print_ascii
        return
    }

    # Colors.
    ascii_data="${ascii_data//\$\{c1\}/$c1}"
    ascii_data="${ascii_data//\$\{c2\}/$c2}"
    ascii_data="${ascii_data//\$\{c3\}/$c3}"
    ascii_data="${ascii_data//\$\{c4\}/$c4}"
    ascii_data="${ascii_data//\$\{c5\}/$c5}"
    ascii_data="${ascii_data//\$\{c6\}/$c6}"

    ((text_padding=ascii_len+gap))
    printf '%b\n' "$ascii_data${reset}"
    LC_ALL=C
}

get_image_source() {
    case $image_source in
        "auto" | "wall" | "wallpaper")
            get_wallpaper
        ;;

        *)
            # Get the absolute path.
            image_source="$(get_full_path "$image_source")"

            if [[ -d "$image_source" ]]; then
                shopt -s nullglob
                files=("${image_source%/}"/*.{png,jpg,jpeg,jpe,gif,svg})
                shopt -u nullglob
                image="${files[RANDOM % ${#files[@]}]}"

            else
                image="$image_source"
            fi
        ;;
    esac

    err "Image: Using image '$image'"
}

get_wallpaper() {
    case $os in
        "Mac OS X"|"macOS")
            image="$(osascript <<END
                     tell application "System Events" to picture of current desktop
END
)"
        ;;

        "Windows")
            case $distro in
                "Windows XP")
                    image="/c/Documents and Settings/${USER}"
                    image+="/Local Settings/Application Data/Microsoft/Wallpaper1.bmp"

                    [[ "$kernel_name" == *CYGWIN* ]] && image="/cygdrive${image}"
                ;;

                "Windows"*)
                    image="${APPDATA}/Microsoft/Windows/Themes/TranscodedWallpaper.jpg"
                ;;
            esac
        ;;

        *)
            # Get DE if user has disabled the function.
            ((de_run != 1)) && get_de

            type -p wal >/dev/null && [[ -f "${HOME}/.cache/wal/wal" ]] && \
                { image="$(< "${HOME}/.cache/wal/wal")"; return; }

            case $de in
                "MATE"*)
                    image="$(gsettings get org.mate.background picture-filename)"
                ;;

                "Xfce"*)
                    image="$(xfconf-query -c xfce4-desktop -p \
                             "/backdrop/screen0/monitor0/workspace0/last-image")"
                ;;

                "Cinnamon"*)
                    image="$(gsettings get org.cinnamon.desktop.background picture-uri)"
                    image="$(decode_url "$image")"
                ;;

                "GNOME"*)
                    image="$(gsettings get org.gnome.desktop.background picture-uri)"
                    image="$(decode_url "$image")"
                ;;

                "Plasma"*)
                    image=$XDG_CONFIG_HOME/plasma-org.kde.plasma.desktop-appletsrc
                    image=$(awk -F '=' '$1 == "Image" { print $2 }' "$image")
                ;;

                "LXQt"*)
                    image="$XDG_CONFIG_HOME/pcmanfm-qt/lxqt/settings.conf"
                    image="$(awk -F '=' '$1 == "Wallpaper" {print $2}' "$image")"
                ;;

                *)
                    if type -p feh >/dev/null && [[ -f "${HOME}/.fehbg" ]]; then
                        image="$(awk -F\' '/feh/ {printf $(NF-1)}' "${HOME}/.fehbg")"

                    elif type -p setroot >/dev/null && \
                         [[ -f "${XDG_CONFIG_HOME}/setroot/.setroot-restore" ]]; then
                        image="$(awk -F\' '/setroot/ {printf $(NF-1)}' \
                                 "${XDG_CONFIG_HOME}/setroot/.setroot-restore")"

                    elif type -p nitrogen >/dev/null; then
                        image="$(awk -F'=' '/file/ {printf $2;exit;}' \
                                 "${XDG_CONFIG_HOME}/nitrogen/bg-saved.cfg")"

                    else
                        image="$(gsettings get org.gnome.desktop.background picture-uri)"
                        image="$(decode_url "$image")"
                    fi
                ;;
            esac

            # Strip un-needed info from the path.
            image="${image/file:\/\/}"
            image="$(trim_quotes "$image")"
        ;;
    esac

    # If image is an xml file, don't use it.
    [[ "${image/*\./}" == "xml" ]] && image=""
}

get_w3m_img_path() {
    # Find w3m-img path.
    shopt -s nullglob
    w3m_paths=({/usr/{local/,},~/.nix-profile/}{lib,libexec,lib64,libexec64}/w3m/w3mi*)
    shopt -u nullglob

    [[ -x "${w3m_paths[0]}" ]] && \
        { w3m_img_path="${w3m_paths[0]}"; return; }

    err "Image: w3m-img wasn't found on your system"
}

get_window_size() {
    # This functions gets the current window size in
    # pixels.
    #
    # We first try to use the escape sequence "\033[14t"
    # to get the terminal window size in pixels. If this
    # fails we then fallback to using "xdotool" or other
    # programs.

    # Tmux has a special way of reading escape sequences
    # so we have to use a slightly different sequence to
    # get the terminal size.
    if [[ "$image_backend" == "tycat" ]]; then
        printf '%b' '\e}qs\000'

    elif [[ -z $VTE_VERSION ]]; then
        case ${TMUX:-null} in
            "null") printf '%b' '\e[14t' ;;
            *)      printf '%b' '\ePtmux;\e\e[14t\e\\ ' ;;
        esac
    fi

    # The escape codes above print the desired output as
    # user input so we have to use read to store the out
    # -put as a variable.
    # The 1 second timeout is required for older bash
    #
    # False positive.
    # shellcheck disable=2141
    case $bash_version in
        4|5) IFS=';t' read -d t -t 0.05 -sra term_size ;;
        *)   IFS=';t' read -d t -t 1 -sra term_size ;;
    esac
    unset IFS

    # Split the string into height/width.
    if [[ "$image_backend" == "tycat" ]]; then
        term_width="$((term_size[2] * term_size[0]))"
        term_height="$((term_size[3] * term_size[1]))"

    else
        term_height="${term_size[1]}"
        term_width="${term_size[2]}"
    fi

    # Get terminal width/height.
    if (( "${term_width:-0}" < 50 )) && [[ "$DISPLAY" && $os != "Mac OS X" && $os != "macOS" ]]; then
        if type -p xdotool &>/dev/null; then
            IFS=$'\n' read -d "" -ra win \
                <<< "$(xdotool getactivewindow getwindowgeometry --shell %1)"
            term_width="${win[3]/WIDTH=}"
            term_height="${win[4]/HEIGHT=}"

        elif type -p xwininfo &>/dev/null; then
            # Get the focused window's ID.
            if type -p xdo &>/dev/null; then
                current_window="$(xdo id)"

            elif type -p xprop &>/dev/null; then
                current_window="$(xprop -root _NET_ACTIVE_WINDOW)"
                current_window="${current_window##* }"

            elif type -p xdpyinfo &>/dev/null; then
                current_window="$(xdpyinfo | grep -F "focus:")"
                current_window="${current_window/*window }"
                current_window="${current_window/,*}"
            fi

            # If the ID was found get the window size.
            if [[ "$current_window" ]]; then
                term_size=("$(xwininfo -id "$current_window")")
                term_width="${term_size[0]#*Width: }"
                term_width="${term_width/$'\n'*}"
                term_height="${term_size[0]/*Height: }"
                term_height="${term_height/$'\n'*}"
            fi
        fi
    fi

    term_width="${term_width:-0}"
}


get_term_size() {
    # Get the terminal size in cells.
    read -r lines columns <<< "$(stty size)"

    # Calculate font size.
    font_width="$((term_width / columns))"
    font_height="$((term_height / lines))"
}

get_image_size() {
    # This functions determines the size to make the thumbnail image.
    get_term_size

    case $image_size in
        "auto")
            image_size="$((columns * font_width / 2))"
            term_height="$((term_height - term_height / 4))"

            ((term_height < image_size)) && \
                image_size="$term_height"
        ;;

        *"%")
            percent="${image_size/\%}"
            image_size="$((percent * term_width / 100))"

            (((percent * term_height / 50) < image_size)) && \
                image_size="$((percent * term_height / 100))"
        ;;

        "none")
            # Get image size so that we can do a better crop.
            read -r width height <<< "$(identify -format "%w %h" "$image")"

            while ((width >= (term_width / 2) || height >= term_height)); do
                ((width=width/2,height=height/2))
            done

            crop_mode="none"
        ;;

        *)  image_size="${image_size/px}" ;;
    esac

    # Check for terminal padding.
    [[ "$image_backend" == "w3m" ]] && term_padding

    width="${width:-$image_size}"
    height="${height:-$image_size}"
    text_padding="$(((width + padding + xoffset) / font_width + gap))"
}

make_thumbnail() {
    # Name the thumbnail using variables so we can
    # use it later.
    image_name="${crop_mode}-${crop_offset}-${width}-${height}-${image//\/}"

    # Handle file extensions.
    case ${image##*.} in
        "eps"|"pdf"|"svg"|"gif"|"png")
            image_name+=".png" ;;
        *)  image_name+=".jpg" ;;
    esac

    # Create the thumbnail dir if it doesn't exist.
    mkdir -p "${thumbnail_dir:=${XDG_CACHE_HOME:-${HOME}/.cache}/thumbnails/neofetch}"

    if [[ ! -f "${thumbnail_dir}/${image_name}" ]]; then
        # Get image size so that we can do a better crop.
        [[ -z "$size" ]] && {
            read -r og_width og_height <<< "$(identify -format "%w %h" "$image")"
            ((og_height > og_width)) && size="$og_width" || size="$og_height"
        }

        case $crop_mode in
            "fit")
                c="$(convert "$image" \
                    -colorspace srgb \
                    -format "%[pixel:p{0,0}]" info:)"

                convert \
                    -background none \
                    "$image" \
                    -trim +repage \
                    -gravity south \
                    -background "$c" \
                    -extent "${size}x${size}" \
                    -scale "${width}x${height}" \
                    "${thumbnail_dir}/${image_name}"
            ;;

            "fill")
                convert \
                    -background none \
                    "$image" \
                    -trim +repage \
                    -scale "${width}x${height}^" \
                    -extent "${width}x${height}" \
                    "${thumbnail_dir}/${image_name}"
            ;;

            "none")
                cp "$image" "${thumbnail_dir}/${image_name}"
            ;;

            *)
                convert \
                    -background none \
                    "$image" \
                    -strip \
                    -gravity "$crop_offset" \
                    -crop "${size}x${size}+0+0" \
                    -scale "${width}x${height}" \
                    "${thumbnail_dir}/${image_name}"
            ;;
        esac
    fi

    # The final image.
    image="${thumbnail_dir}/${image_name}"
}

display_image() {
    case $image_backend in
        "caca")
            img2txt \
                -W "$((width / font_width))" \
                -H "$((height / font_height))" \
                --gamma=0.6 \
            "$image"
        ;;


        "ueberzug")
            if [ "$wait" = true ];then
                wait=false;
            else
                ueberzug layer --parser bash 0< <(
                    declare -Ap ADD=(\
                        [action]="add"\
                        [identifier]="neofetch"\
                        [x]=$xoffset [y]=$yoffset\
                        [path]=$image\
                    )
                    read -rs
                )
            fi
        ;;

        "catimg")
            catimg -w "$((width*catimg_size / font_width))" -r "$catimg_size" "$image"
        ;;

        "chafa")
            chafa --stretch --size="$((width / font_width))x$((height / font_height))" "$image"
        ;;

        "jp2a")
            jp2a \
                --colors \
                --width="$((width / font_width))" \
                --height="$((height / font_height))" \
            "$image"
        ;;

        "kitty")
            kitty +kitten icat \
                --align left \
                --place "$((width/font_width))x$((height/font_height))@${xoffset}x${yoffset}" \
            "$image"
        ;;

        "pot")
            pot \
                "$image" \
                --size="$((width / font_width))x$((height / font_height))"
        ;;

        "pixterm")
            pixterm \
                -tc "$((width / font_width))" \
                -tr "$((height / font_height))" \
            "$image"
        ;;

        "sixel")
            img2sixel \
                -w "$width" \
                -h "$height" \
            "$image"
        ;;

        "termpix")
            termpix \
                --width "$((width / font_width))" \
                --height "$((height / font_height))" \
            "$image"
        ;;

        "iterm2")
            printf -v iterm_cmd '\e]1337;File=width=%spx;height=%spx;inline=1:%s' \
                "$width" "$height" "$(base64 < "$image")"

            # Tmux requires an additional escape sequence for this to work.
            [[ -n "$TMUX" ]] && printf -v iterm_cmd '\ePtmux;\e%b\e'\\ "$iterm_cmd"

            printf '%b\a\n' "$iterm_cmd"
        ;;

        "tycat")
            tycat \
                -g "${width}x${height}" \
            "$image"
        ;;

        "viu")
            viu \
                -t -w "$((width / font_width))" -h "$((height / font_height))" \
            "$image"
        ;;

        "w3m")
            get_w3m_img_path
            zws='\xE2\x80\x8B\x20'

            # Add a tiny delay to fix issues with images not
            # appearing in specific terminal emulators.
            ((bash_version>3)) && sleep 0.05
            printf '%b\n%s;\n%s\n' "0;1;$xoffset;$yoffset;$width;$height;;;;;$image" 3 4 |\
            "${w3m_img_path:-false}" -bg "$background_color" &>/dev/null
        ;;
    esac
}

to_ascii() {
    err "$1"
    image_backend="ascii"
    print_ascii

    # Set cursor position next image/ascii.
    printf '\e[%sA\e[9999999D' "${lines:-0}"
}

to_off() {
    err "$1"
    image_backend="off"
    text_padding=
}

