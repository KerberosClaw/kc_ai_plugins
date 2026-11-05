#!/usr/bin/env bash
# owl_lock.sh — one lock per shared resource (a production environment, a browser profile,
# a shared account). Protocol: ../references/lock.md
#
#   owl_lock.sh [-n NAME] acquire   <owner-id> <step>   take the lock; refresh step and heartbeat if already yours
#   owl_lock.sh [-n NAME] heartbeat <owner-id>          refresh the heartbeat (every 10 minutes while holding)
#   owl_lock.sh [-n NAME] release   <owner-id>          release (owner only)
#   owl_lock.sh [-n NAME] status                        show who holds it
#   owl_lock.sh [-n NAME] force-release <reason>        humans only; refuses to run without a terminal
#
# NAME defaults to "prod". The lock is the directory $OWL_LOCK_ROOT/NAME.lock.d
# (OWL_LOCK_ROOT defaults to ~/.owl/locks); every acquire/release/force-release is appended to
# $OWL_LOCK_ROOT/NAME.log. A lock whose heartbeat is older than OWL_LOCK_STALE_MIN minutes
# (default 30) is reported as possibly stale. It is never cleared automatically.
#
# Exit codes:
#   acquire    0 taken (or already yours)   1 held by someone else, owner file missing, or the
#                                             owner file could not be written   2 usage/config error
#   heartbeat  0 refreshed                  1 not held, not yours, or write failed     2 usage/config error
#   release    0 released (or not held)     1 not yours / owner file missing, left alone   2 usage/config error
#   status     0 free                       1 held, heartbeat fresh   3 held, heartbeat stale or owner file missing
#   Treat every exit code other than 0 from acquire as "not taken".
#
# Portable across Linux and macOS: times are stored as epoch seconds, no GNU-only date flags.

set -u
NAME=prod
if [ "${1:-}" = "-n" ]; then NAME="${2:-}"; shift 2 || true; fi
[[ "$NAME" =~ ^[A-Za-z0-9._-]{1,64}$ ]] || { echo "invalid lock name: $NAME" >&2; exit 2; }

ROOT="${OWL_LOCK_ROOT:-$HOME/.owl/locks}"
LOCK="$ROOT/$NAME.lock.d"
LOG="$ROOT/$NAME.log"
STALE_MIN="${OWL_LOCK_STALE_MIN:-30}"
[[ "$STALE_MIN" =~ ^[0-9]+$ ]] || { echo "OWL_LOCK_STALE_MIN must be a whole number of minutes: $STALE_MIN" >&2; exit 2; }

now_epoch() { date +%s; }
now_text() { date '+%Y-%m-%dT%H:%M:%S%z'; }
log() { mkdir -p "$ROOT"; printf '%s\t%s\n' "$(now_text)" "$*" >> "$LOG"; }
field() { sed -n "s/^$1: //p" "$LOCK/owner" 2>/dev/null | head -1; }
age_min() {  # minutes since last heartbeat; -1 when unreadable
  local hb; hb=$(field heartbeat_epoch)
  [[ "$hb" =~ ^[0-9]+$ ]] || { echo -1; return; }
  echo $(( ( $(now_epoch) - hb ) / 60 ))
}
write_owner() {  # $1 id  $2 step  $3 started_text
  local tmp="$LOCK/.owner.$$"
  printf 'id: %s\nstep: %s\nhost: %s\nstarted: %s\nheartbeat: %s\nheartbeat_epoch: %s\n' \
    "$1" "$2" "$(hostname)" "$3" "$(now_text)" "$(now_epoch)" > "$tmp" 2>/dev/null && mv -f "$tmp" "$LOCK/owner" 2>/dev/null \
    || { rm -f "$tmp" 2>/dev/null; echo "could not write the owner file in $LOCK" >&2; return 1; }
}
owner_missing() { [ -d "$LOCK" ] && [ ! -f "$LOCK/owner" ]; }
missing_note() { echo "lock $NAME: the directory exists but its owner file is missing; hand it to a human (force-release), do not clear it yourself" >&2; }
show() {
  if [ ! -d "$LOCK" ]; then echo "lock $NAME: free"; return; fi
  local a; a=$(age_min)
  echo "lock $NAME: held by $(field id)"
  echo "  step:    $(field step)"
  echo "  host:    $(field host)"
  echo "  started: $(field started)"
  if [ "$a" -lt 0 ]; then echo "  heartbeat: unreadable (owner file missing or being written)"
  else echo "  heartbeat: $a min ago"; fi
}
valid_id() { [[ "$1" =~ ^[A-Za-z0-9._-]{1,64}$ ]]; }

cmd="${1:-}"; shift || true
case "$cmd" in
  acquire)
    [ $# -eq 2 ] && valid_id "$1" || { echo "usage: owl_lock.sh [-n NAME] acquire <owner-id> <step>  (id: letters, digits, . _ -)" >&2; exit 2; }
    [ -L "$LOCK" ] && { echo "lock path is a symlink, refusing: $LOCK" >&2; exit 2; }
    mkdir -p "$ROOT"
    if mkdir "$LOCK" 2>/dev/null; then
      if ! write_owner "$1" "$2" "$(now_text)"; then rmdir "$LOCK" 2>/dev/null; echo "lock $NAME not taken" >&2; exit 1; fi
      log "acquire	$1	$2"; echo "lock $NAME taken by $1 ($2)"; exit 0
    fi
    if owner_missing; then missing_note; show; exit 1; fi
    if [ "$(field id)" = "$1" ]; then
      write_owner "$1" "$2" "$(field started)" || exit 1
      log "reacquire	$1	$2"; echo "lock $NAME was already yours; step and heartbeat refreshed ($1: $2)"; exit 0
    fi
    show; exit 1 ;;
  heartbeat)
    [ $# -eq 1 ] || { echo "usage: owl_lock.sh [-n NAME] heartbeat <owner-id>" >&2; exit 2; }
    owner_missing && { missing_note; exit 1; }
    [ -d "$LOCK" ] && [ "$(field id)" = "$1" ] || { echo "lock $NAME is not held by $1; nothing refreshed" >&2; show; exit 1; }
    write_owner "$1" "$(field step)" "$(field started)" || exit 1
    exit 0 ;;
  release)
    [ $# -eq 1 ] || { echo "usage: owl_lock.sh [-n NAME] release <owner-id>" >&2; exit 2; }
    [ -d "$LOCK" ] || { echo "lock $NAME: already free"; exit 0; }
    owner_missing && { missing_note; exit 1; }
    [ "$(field id)" = "$1" ] || { echo "lock $NAME is not held by $1; left alone" >&2; show; exit 1; }
    rm -f "$LOCK/owner" "$LOCK"/.owner.* && rmdir "$LOCK" && { log "release	$1"; echo "lock $NAME released ($1)"; exit 0; }
    echo "release failed: unexpected files in $LOCK" >&2; exit 1 ;;
  status)
    show
    [ -d "$LOCK" ] || exit 0
    a=$(age_min)
    if [ "$a" -lt 0 ] || [ "$a" -ge "$STALE_MIN" ]; then
      echo "  ! heartbeat older than $STALE_MIN min: possibly stale. Tell a human; do not clear it yourself."; exit 3
    fi
    exit 1 ;;
  force-release)
    [ $# -ge 1 ] || { echo "usage: owl_lock.sh [-n NAME] force-release <reason>  (humans only)" >&2; exit 2; }
    # Only stops obvious non-interactive calls. Agents must not use force-release at all;
    # that is enforced by the protocol, not by this check.
    [ -t 0 ] || { echo "force-release must be run by a human from a terminal" >&2; exit 2; }
    [ -d "$LOCK" ] || { echo "lock $NAME: already free"; exit 0; }
    show; prev=$(field id)
    rm -rf "$LOCK"; log "force-release	$prev	$*"; echo "lock $NAME force-released (was held by $prev; reason: $*)"; exit 0 ;;
  *)
    sed -n '2,23p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
