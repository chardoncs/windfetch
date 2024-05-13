get_users() {
    users="$(who | awk '!seen[$1]++ {printf $1 ", "}')"
    users="${users%\,*}"
}

