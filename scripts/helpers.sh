#!/usr/bin/env sh
# helpers.sh - tmux option reading utilities for tmux-ai-status
# POSIX sh compatible

# Get a tmux option value, falling back to a default
# Usage: get_tmux_option "@option-name" "default_value"
get_tmux_option() {
    option_name="$1"
    default_value="$2"
    option_value=$(tmux show-option -gqv "$option_name")
    if [ -n "$option_value" ]; then
        echo "$option_value"
    else
        echo "$default_value"
    fi
}

# Set a tmux option
# Usage: set_tmux_option "@option-name" "value"
set_tmux_option() {
    tmux set-option -gq "$1" "$2"
}

# Get the current value of status-right or status-left
# Usage: get_status_string "right"
get_status_string() {
    position="$1"
    tmux show-option -gqv "status-${position}"
}

# Interpolate a placeholder in status string with a command
# Replaces #{ai_status} with #(script_path) in the status bar
# Usage: interpolate_status "right" "#{ai_status}" "#(/path/to/script.sh)"
interpolate_status() {
    position="$1"
    placeholder="$2"
    replacement="$3"
    current=$(get_status_string "$position")
    if [ -z "$current" ]; then
        return
    fi
    new_value=$(echo "$current" | sed "s|${placeholder}|${replacement}|g")
    set_tmux_option "status-${position}" "$new_value"
}
