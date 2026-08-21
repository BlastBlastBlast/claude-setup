# macOS helpers — source from your ~/.zshrc:
#     source /path/to/claude-setup/shell/macos.sh
# Provides `screensaver` (start the screensaver now) and `awake` (bounded
# keep-awake, so unattended agent runs survive an idle Mac).

# ── screensaver — start the screensaver now ──────────────────────────────────
screensaver() {
    open -a ScreenSaverEngine
}

# ── awake — keep the Mac from sleeping, for a bounded time ───────────────────
# Usage:
#     awake [DURATION] [-d]   turn on (default 3h)
#     awake off               turn off early
#     awake status            show remaining time
#
# DURATION: 3h, 90m, 2h30m, 45s — a bare number means hours (`awake 1.5`).
# -d / --display also keeps the screen awake; by default the display is free
# to sleep while the machine stays up.
#
# Prevents *idle* sleep. Closing the lid still sleeps the Mac unless it is in
# clamshell mode (external display + power adapter).

_AWAKE_PID_FILE="${XDG_STATE_HOME:-$HOME/.local/state}/awake.pid"

awake() {
    case "${1:-}" in
        off|stop)        _awake_stop; return $? ;;
        status|st)       _awake_status; return $? ;;
        -h|--help|help)  _awake_usage; return 0 ;;
    esac

    local keep_display=0 spec=""
    while (( $# )); do
        case "$1" in
            -d|--display) keep_display=1 ;;
            -*) print -u2 "awake: unknown option '$1'"; _awake_usage; return 2 ;;
            *)  spec="$1" ;;
        esac
        shift
    done

    local secs
    if ! secs="$(_awake_seconds "${spec:-3h}")"; then
        print -u2 "awake: bad duration '${spec}' — try 3h, 90m, 2h30m"
        return 2
    fi

    _awake_stop >/dev/null 2>&1  # replace any session already running

    # -i no idle sleep, -m no disk idle sleep, -s no sleep at all (AC only),
    # -d only when asked, so the screen can still go dark to save battery.
    local flags="-ims"
    (( keep_display )) && flags="-dims"

    mkdir -p "${_AWAKE_PID_FILE:h}"
    nohup caffeinate "$flags" -t "$secs" >/dev/null 2>&1 &
    local pid=$!
    disown 2>/dev/null
    print -- "$pid $(( $(date +%s) + secs ))" > "$_AWAKE_PID_FILE"

    local note=""
    (( keep_display )) && note=", display stays on"
    print -- "awake: on for $(_awake_human "$secs") — until $(date -v"+${secs}S" '+%H:%M')${note}"
}

_awake_usage() {
    print -- "usage: awake [DURATION|off|status] [-d]"
    print -- "       DURATION: 3h (default), 90m, 2h30m, 45s; bare number = hours"
    print -- "       -d, --display   keep the screen on too"
}

# Reads the pid file; echoes "<pid> <end-epoch>" and returns 0 only when the
# recorded pid is still a live caffeinate (guards against pid reuse).
_awake_read() {
    [[ -f "$_AWAKE_PID_FILE" ]] || return 1
    local pid until_ts
    read -r pid until_ts < "$_AWAKE_PID_FILE"
    if [[ -z "$pid" ]] || ! ps -o comm= -p "$pid" 2>/dev/null | grep -q 'caffeinate$'; then
        rm -f "$_AWAKE_PID_FILE"
        return 1
    fi
    print -- "$pid $until_ts"
}

_awake_stop() {
    local pid until_ts
    if ! read -r pid until_ts <<< "$(_awake_read)" || [[ -z "$pid" ]]; then
        print -- "awake: off (nothing running)"
        return 1
    fi
    kill "$pid" 2>/dev/null
    rm -f "$_AWAKE_PID_FILE"
    print -- "awake: off"
}

_awake_status() {
    local pid until_ts left
    if ! read -r pid until_ts <<< "$(_awake_read)" || [[ -z "$pid" ]]; then
        print -- "awake: off"
        return 1
    fi
    left=$(( until_ts - $(date +%s) ))
    (( left < 0 )) && left=0
    print -- "awake: on — $(_awake_human "$left") left (until $(date -r "$until_ts" '+%H:%M'))"
}

_awake_human() {
    local s=$1 h m
    h=$(( s / 3600 ))
    m=$(( (s % 3600) / 60 ))
    if (( h && m ));  then print -- "${h}h${m}m"
    elif (( h ));     then print -- "${h}h"
    elif (( m ));     then print -- "${m}m"
    else                   print -- "${s}s"
    fi
}

# Duration spec -> whole seconds on stdout; non-zero exit on a spec it can't parse.
_awake_seconds() {
    local spec="${1:l}" rest total=0 num unit

    if [[ "$spec" =~ '^[0-9]+(\.[0-9]+)?$' ]]; then
        printf '%.0f\n' "$(( spec * 3600 ))"
        return 0
    fi

    rest="$spec"
    while [[ -n "$rest" ]]; do
        [[ "$rest" =~ '^([0-9]+(\.[0-9]+)?)([hms])' ]] || return 1
        num="$match[1]"; unit="$match[3]"
        case "$unit" in
            h) total=$(( total + num * 3600 )) ;;
            m) total=$(( total + num * 60 )) ;;
            s) total=$(( total + num )) ;;
        esac
        rest="${rest#$MATCH}"
    done

    (( total >= 1 )) || return 1
    printf '%.0f\n' "$total"
}
