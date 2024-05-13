get_shell() {
    case $shell_path in
        on)  shell="$SHELL " ;;
        off) shell="${SHELL##*/} " ;;
    esac

    [[ $shell_version != on ]] && return

    case ${shell_name:=${SHELL##*/}} in
        bash)
            [[ $BASH_VERSION ]] ||
                BASH_VERSION=$("$SHELL" -c "printf %s \"\$BASH_VERSION\"")

            shell+=${BASH_VERSION/-*}
        ;;

        sh|ash|dash|es) ;;

        *ksh)
            shell+=$("$SHELL" -c "printf %s \"\$KSH_VERSION\"")
            shell=${shell/ * KSH}
            shell=${shell/version}
        ;;

        osh)
            if [[ $OIL_VERSION ]]; then
                shell+=$OIL_VERSION
            else
                shell+=$("$SHELL" -c "printf %s \"\$OIL_VERSION\"")
            fi
        ;;

        tcsh)
            shell+=$("$SHELL" -c "printf %s \$tcsh")
        ;;

        yash)
            shell+=$("$SHELL" --version 2>&1)
            shell=${shell/ $shell_name}
            shell=${shell/ Yet another shell}
            shell=${shell/Copyright*}
        ;;

        nu)
            shell+=$("$SHELL" -c "version | get version")
            shell=${shell/ $shell_name}
        ;;


        *)
            shell+=$("$SHELL" --version 2>&1)
            shell=${shell/ $shell_name}
        ;;
    esac

    # Remove unwanted info.
    shell=${shell/, version}
    shell=${shell/xonsh\//xonsh }
    shell=${shell/options*}
    shell=${shell/\(*\)}
}

