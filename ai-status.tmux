#!/usr/bin/env sh
# ai-status.tmux - TPM entrypoint for tmux-ai-status plugin
# Registers #{ai_status} interpolation and configures the status bar

PLUGIN_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPTS_DIR="$PLUGIN_DIR/scripts"

. "$SCRIPTS_DIR/helpers.sh"

# --- Read user configuration ---
position=$(get_tmux_option "@ai-status-position" "right")
interval=$(get_tmux_option "@ai-status-interval" "5")

# --- Set status-interval ---
current_interval=$(tmux show-option -gqv "status-interval")
# Only lower the interval if current is higher or unset
if [ -z "$current_interval" ] || [ "$current_interval" -gt "$interval" ] 2>/dev/null; then
    tmux set-option -gq "status-interval" "$interval"
fi

# --- Build the status command ---
status_cmd="#($SCRIPTS_DIR/ai-status.sh)"

# --- Register in status bar ---
# Strategy: if #{ai_status} placeholder exists, replace it.
# Otherwise, prepend to the configured position.
current_status=$(get_status_string "$position")

case "$current_status" in
    *'#{ai_status}'*)
        # Replace the placeholder
        interpolate_status "$position" '#{ai_status}' "$status_cmd"
        ;;
    *)
        # Prepend to existing status string
        if [ -n "$current_status" ]; then
            set_tmux_option "status-${position}" "${status_cmd}${current_status}"
        else
            set_tmux_option "status-${position}" "$status_cmd"
        fi
        ;;
esac
