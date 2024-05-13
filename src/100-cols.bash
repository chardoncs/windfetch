get_cols() {
    local blocks blocks2 cols

    if [[ "$color_blocks" == "on" ]]; then
        # Convert the width to space chars.
        printf -v block_width "%${block_width}s"

        # Generate the string.
        for ((block_range[0]; block_range[0]<=block_range[1]; block_range[0]++)); do
            case ${block_range[0]} in
                [0-7])
                    printf -v blocks  '%b\e[3%bm\e[4%bm%b' \
                        "$blocks" "${block_range[0]}" "${block_range[0]}" "$block_width"
                ;;

                *)
                    printf -v blocks2 '%b\e[38;5;%bm\e[48;5;%bm%b' \
                        "$blocks2" "${block_range[0]}" "${block_range[0]}" "$block_width"
                ;;
            esac
        done

        # Convert height into spaces.
        printf -v block_spaces "%${block_height}s"

        # Convert the spaces into rows of blocks.
        [[ "$blocks"  ]] && cols+="${block_spaces// /${blocks}[mnl}"
        [[ "$blocks2" ]] && cols+="${block_spaces// /${blocks2}[mnl}"

        # Add newlines to the string.
        cols=${cols%%nl}
        cols=${cols//nl/
[${text_padding}C${zws}}

        # Add block height to info height.
        ((info_height+=block_range[1]>7?block_height+2:block_height+1))

        case $col_offset in
            "auto") printf '\n\e[%bC%b\n' "$text_padding" "${zws}${cols}" ;;
            *) printf '\n\e[%bC%b\n' "$col_offset" "${zws}${cols}" ;;
        esac
    fi

    unset -v blocks blocks2 cols

    # Tell info() that we printed manually.
    prin=1
}

