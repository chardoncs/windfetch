get_packages() {
    # to adjust the number of pkgs per pkg manager
    pkgs_h=0

    # has: Check if package manager installed.
    # dir: Count files or dirs in a glob.
    # pac: If packages > 0, log package manager name.
    # tot: Count lines in command output.
    has() { type -p "$1" >/dev/null && manager=$1; }
    # globbing is intentional here
    # shellcheck disable=SC2206
    dir() { pkgs=($@); ((packages+=${#pkgs[@]})); pac "$((${#pkgs[@]}-pkgs_h))"; }
    pac() { (($1 > 0)) && { managers+=("$1 (${manager})"); manager_string+="${manager}, "; }; }
    tot() {
        IFS=$'\n' read -d "" -ra pkgs <<< "$("$@")";
        ((packages+=${#pkgs[@]}));
        pac "$((${#pkgs[@]}-pkgs_h))";
    }

    # Redefine tot() and dir() for Bedrock Linux.
    [[ -f /bedrock/etc/bedrock-release && $PATH == */bedrock/cross/* ]] && {
        br_strata=$(brl list)
        tot() {
            IFS=$'\n' read -d "" -ra pkgs <<< "$(for s in ${br_strata}; do strat -r "$s" "$@"; done)"
            ((packages+="${#pkgs[@]}"))
            pac "$((${#pkgs[@]}-pkgs_h))";
        }
        dir() {
            local pkgs=()
            # globbing is intentional here
            # shellcheck disable=SC2206
            for s in ${br_strata}; do pkgs+=(/bedrock/strata/$s/$@); done
            ((packages+=${#pkgs[@]}))
            pac "$((${#pkgs[@]}-pkgs_h))"
        }
    }

    case $os in
        Linux|BSD|"iPhone OS"|Solaris)
            # Package Manager Programs.
            has kiss       && tot kiss l
            has cpt-list   && tot cpt-list
            has pacman-key && tot pacman -Qq --color never
            has dpkg       && tot dpkg-query -f '.\n' -W
            has xbps-query && tot xbps-query -l
            has apk        && tot apk info
            has opkg       && tot opkg list-installed
            has pacman-g2  && tot pacman-g2 -Q
            has lvu        && tot lvu installed
            has tce-status && tot tce-status -i
            has pkg_info   && tot pkg_info
            has pkgin      && tot pkgin list
            has tazpkg     && pkgs_h=6 tot tazpkg list && ((packages-=6))
            has sorcery    && tot gaze installed
            has alps       && tot alps showinstalled
            has butch      && tot butch list
            has swupd      && tot swupd bundle-list --quiet
            has pisi       && tot pisi li
            has pacstall   && tot pacstall -L

            # Using the dnf package cache is much faster than rpm.
            if has dnf && type -p sqlite3 >/dev/null && [[ -f /var/cache/dnf/packages.db ]]; then
                pac "$(sqlite3 /var/cache/dnf/packages.db "SELECT count(pkg) FROM installed")"
            else
                has rpm && tot rpm -qa
            fi

            # 'mine' conflicts with minesweeper games.
            [[ -f /etc/SDE-VERSION ]] &&
                has mine && tot mine -q

            # Counting files/dirs.
            # Variables need to be unquoted here. Only Bedrock Linux is affected.
            # $br_prefix is fixed and won't change based on user input so this is safe either way.
            # shellcheck disable=SC2086
            {
            shopt -s nullglob
            has brew    && dir "$(brew --cellar)/* $(brew --caskroom)/*"
            has emerge  && dir "/var/db/pkg/*/*"
            has Compile && dir "/Programs/*/"
            has eopkg   && dir "/var/lib/eopkg/package/*"
            has crew    && dir "${CREW_PREFIX:-/usr/local}/etc/crew/meta/*.filelist"
            has pkgtool && dir "/var/log/packages/*"
            has scratch && dir "/var/lib/scratchpkg/index/*/.pkginfo"
            has kagami  && dir "/var/lib/kagami/pkgs/*"
            has cave    && dir "/var/db/paludis/repositories/cross-installed/*/data/*/ \
                               /var/db/paludis/repositories/installed/data/*/"
            shopt -u nullglob
            }

            # Other (Needs complex command)
            has kpm-pkg && ((packages+=$(kpm  --get-selections | grep -cv deinstall$)))

            has guix && {
                manager=guix-system && tot guix package -p "/run/current-system/profile" -I
                manager=guix-user   && tot guix package -I
            }

            has nix-store && {
                nix-user-pkgs() {
                    nix-store -qR ~/.nix-profile
                    nix-store -qR /etc/profiles/per-user/"$USER"
                }
                manager=nix-system  && tot nix-store -qR /run/current-system/sw
                manager=nix-user    && tot nix-user-pkgs
                manager=nix-default && tot nix-store -qR /nix/var/nix/profiles/default
            }

            # pkginfo is also the name of a python package manager which is painfully slow.
            # TODO: Fix this somehow.
            has pkginfo && tot pkginfo -i

            case $os-$kernel_name in
                BSD-FreeBSD|BSD-DragonFly)
                    has pkg && tot pkg info
                ;;

                BSD-*)
                    has pkg && dir /var/db/pkg/*

                    ((packages == 0)) &&
                        has pkg && tot pkg list
                ;;
            esac

            # List these last as they accompany regular package managers.
            has flatpak && tot flatpak list
            has spm     && tot spm list -i
            has puyo    && dir ~/.puyo/installed

            # Snap hangs if the command is run without the daemon running.
            # Only run snap if the daemon is also running.
            has snap && ps -e | grep -qFm 1 snapd >/dev/null && \
            pkgs_h=1 tot snap list && ((packages-=1))

            # This is the only standard location for appimages.
            # See: https://github.com/AppImage/AppImageKit/wiki
            manager=appimage && has appimaged && dir ~/.local/bin/*.appimage
        ;;

        "Mac OS X"|"macOS"|MINIX)
            has port  && pkgs_h=1 tot port installed && ((packages-=1))
            has brew  && dir "$(brew --cellar)/* $(brew --caskroom)/*"
            has pkgin && tot pkgin list
            has dpkg  && tot dpkg-query -f '.\n' -W

            has nix-store && {
                nix-user-pkgs() {
                    nix-store -qR ~/.nix-profile
                    nix-store -qR /etc/profiles/per-user/"$USER"
                }
                manager=nix-system && tot nix-store -qR /run/current-system/sw
                manager=nix-user   && tot nix-user-pkgs
            }
        ;;

        AIX|FreeMiNT)
            has lslpp && ((packages+=$(lslpp -J -l -q | grep -cv '^#')))
            has rpm   && tot rpm -qa
        ;;

        Windows)
            case $kernel_name in
                CYGWIN*) has cygcheck && tot cygcheck -cd ;;
                MSYS*)   has pacman   && tot pacman -Qq --color never ;;
            esac

            # Scoop environment throws errors if `tot scoop list` is used
            has scoop && pkgs_h=1 dir ~/scoop/apps/* && ((packages-=1))

            # Count chocolatey packages.
            [[ -d /cygdrive/c/ProgramData/chocolatey/lib ]] && \
                dir /cygdrive/c/ProgramData/chocolatey/lib/*
        ;;

        Haiku)
            has pkgman && dir /boot/system/package-links/*
            packages=${packages/pkgman/depot}
        ;;

        IRIX)
            manager=swpkg
            pkgs_h=3 tot versions -b && ((packages-=3))
        ;;
    esac

    if ((packages == 0)); then
        unset packages

    elif [[ $package_managers == on ]]; then
        printf -v packages '%s, ' "${managers[@]}"
        packages=${packages%,*}

    elif [[ $package_managers == tiny ]]; then
        packages+=" (${manager_string%,*})"
    fi

    packages=${packages/pacman-key/pacman}
}

