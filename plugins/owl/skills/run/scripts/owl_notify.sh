#!/usr/bin/env bash
# owl_notify.sh — the bundled sender for the owl notification contract (../references/notify.md).
# Copy it to a fixed path on the machine that runs the dispatch and name that path in owl.md.
#
#   owl_notify.sh <event> <message> [result-path]
#
#   event        started | progress | attention | needs_you | completed | failed
#   message      one line; newlines are flattened
#   result-path  optional file on this machine. Images (png/jpg/webp) are attached where the
#                channel allows it; any other file is mentioned by path in the message.
#
# Environment:
#   OWL_TASK              dispatch name, shown in the message (set by owl)
#   OWL_NOTIFY_CHANNEL    telegram | discord | slack | imessage   (required)
#   OWL_NOTIFY_CONFIG     optional private env file to source first (a TRUSTED shell file you own).
#                         A leading ~ is expanded. When unset, ~/.config/owl/notify.env is read if it exists.
#   OWL_NOTIFY_DRY_RUN=1  print what would be sent and exit 0; nothing is sent (use it for tests)
#   telegram : TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID
#   discord  : DISCORD_WEBHOOK_URL
#   slack    : SLACK_WEBHOOK_URL
#   imessage : IMESSAGE_TO   (macOS only)
#
# Credentials come only from the environment or OWL_NOTIFY_CONFIG. Never hard-code them, never
# commit them, never write them into a dispatch or owl.md.
#
# Exit code 0 means the channel accepted the message; anything else is a failed send, so the
# pre-flight test in owl:run can gate on it. For imessage, 0 only means the message was handed to
# the Messages app; delivery to the phone is not confirmed. Retrying and logging are owl:run's job.
# Requirements: curl; python3 for JSON escaping (discord/slack). On macOS python3 comes with the
# command line developer tools (xcode-select --install).
set -uo pipefail

EVENT="${1:-}"; TEXT="${2:-}"; RESULT="${3:-}"
die(){ echo "[owl_notify] $*" >&2; exit 1; }
[ -n "$EVENT" ] && [ -n "$TEXT" ] || die "usage: owl_notify.sh <event> <message> [result-path]"

case "$EVENT" in
  started|progress|completed) LIGHT="🟢" ;;
  attention)                  LIGHT="🟡" ;;
  needs_you|failed)           LIGHT="🔴" ;;
  *) die "unknown event: $EVENT (started|progress|attention|needs_you|completed|failed)" ;;
esac

CONF="${OWL_NOTIFY_CONFIG:-}"
case "$CONF" in "~/"*) CONF="$HOME/${CONF#\~/}" ;; "~") CONF="$HOME" ;; esac
if [ -n "$CONF" ]; then
  [ -f "$CONF" ] || die "OWL_NOTIFY_CONFIG not found: $CONF"
elif [ -f "$HOME/.config/owl/notify.env" ]; then
  CONF="$HOME/.config/owl/notify.env"
fi
if [ -n "$CONF" ]; then
  set -a; # shellcheck disable=SC1090
  source "$CONF"; set +a
fi
CH="${OWL_NOTIFY_CHANNEL:-}"
[ -n "$CH" ] || die "OWL_NOTIFY_CHANNEL is not set (telegram|discord|slack|imessage)"

TEXT="$(printf '%s' "$TEXT" | tr '\r\n' '  ')"
MSG="${LIGHT} ${OWL_TASK:+[$OWL_TASK] }${EVENT}: ${TEXT}"
MEDIA=""
if [ -n "$RESULT" ]; then
  case "$RESULT" in
    *.png|*.PNG|*.jpg|*.JPG|*.jpeg|*.JPEG|*.webp|*.WEBP) [ -f "$RESULT" ] && MEDIA="$RESULT" ;;
  esac
  [ -n "$MEDIA" ] || MSG="${MSG} (result: ${RESULT})"
fi

# Runs in a command substitution, so it can only return; callers must check the status.
json_str(){ command -v python3 >/dev/null 2>&1 || return 1
            printf '%s' "$1" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))'; }
post(){ curl --fail --show-error --silent --max-time 25 "$@"; }

if [ "${OWL_NOTIFY_DRY_RUN:-}" = "1" ]; then
  echo "[owl_notify] dry run, nothing sent: channel=$CH media=${MEDIA:-none} message=$MSG"; exit 0
fi

case "$CH" in
  telegram)
    : "${TELEGRAM_BOT_TOKEN:?set TELEGRAM_BOT_TOKEN}"; : "${TELEGRAM_CHAT_ID:?set TELEGRAM_CHAT_ID}"
    api="https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}"
    if [ -n "$MEDIA" ]; then
      post -F chat_id="$TELEGRAM_CHAT_ID" -F caption="$MSG" -F photo="@${MEDIA}" "$api/sendPhoto" >/dev/null || die "telegram send failed"
    else
      post "$api/sendMessage" -d chat_id="$TELEGRAM_CHAT_ID" --data-urlencode text="$MSG" >/dev/null || die "telegram send failed"
    fi ;;
  discord)
    : "${DISCORD_WEBHOOK_URL:?set DISCORD_WEBHOOK_URL}"
    if [ -n "$MEDIA" ]; then
      post -F "content=$MSG" -F "file1=@${MEDIA}" "$DISCORD_WEBHOOK_URL" >/dev/null || die "discord send failed"
    else
      J="$(json_str "$MSG")" || die "discord needs python3 for JSON escaping; nothing sent"
      post -H "Content-Type: application/json" -d "{\"content\":$J}" "$DISCORD_WEBHOOK_URL" >/dev/null || die "discord send failed"
    fi ;;
  slack)
    : "${SLACK_WEBHOOK_URL:?set SLACK_WEBHOOK_URL}"
    [ -n "$MEDIA" ] && MSG="${MSG} (image: ${MEDIA})"
    J="$(json_str "$MSG")" || die "slack needs python3 for JSON escaping; nothing sent"
    post -H "Content-Type: application/json" -d "{\"text\":$J}" "$SLACK_WEBHOOK_URL" >/dev/null || die "slack send failed" ;;
  imessage)
    : "${IMESSAGE_TO:?set IMESSAGE_TO}"; command -v osascript >/dev/null 2>&1 || die "imessage needs macOS osascript"
    [ -n "$MEDIA" ] && MSG="${MSG} (image: ${MEDIA})"
    osascript - "$IMESSAGE_TO" "$MSG" <<'APPLESCRIPT' >/dev/null || die "imessage send failed"
on run argv
  tell application "Messages" to send (item 2 of argv) to buddy (item 1 of argv)
end run
APPLESCRIPT
    ;;
  *) die "unknown OWL_NOTIFY_CHANNEL=$CH (telegram|discord|slack|imessage)" ;;
esac
if [ "$CH" = "imessage" ]; then echo "[owl_notify] handed to the Messages app (delivery not confirmed)"
else echo "[owl_notify] sent via $CH"; fi
