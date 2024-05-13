version=0.1.0

# Fallback to a value of '5' for shells which support bash
# but do not set the 'BASH_' shell variables (osh).
bash_version=${BASH_VERSINFO[0]:-5}
shopt -s eval_unsafe_arith &>/dev/null

sys_locale=${LANG:-C}
XDG_CONFIG_HOME=${XDG_CONFIG_HOME:-${HOME}/.config}
PATH=$PATH:/usr/xpg4/bin:/usr/sbin:/sbin:/usr/etc:/usr/libexec
reset='\e[0m'
shopt -s nocasematch

# Speed up script by not using unicode.
LC_ALL=C
LANG=C

# Fix issues with gsettings.
export GIO_EXTRA_MODULES=/usr/lib/x86_64-linux-gnu/gio/modules/

