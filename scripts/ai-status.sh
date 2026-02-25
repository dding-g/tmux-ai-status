#!/usr/bin/env sh
# ai-status.sh - Detect AI coding tools running in the current tmux pane
# Uses terminal content scraping (tmux capture-pane) for accurate state detection
# POSIX sh compatible, works on macOS and Linux

CURRENT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$CURRENT_DIR/helpers.sh"

# --- Configuration ---
tools=$(get_tmux_option "@ai-status-tools" "claude,opencode,aider,copilot")
busy_icon=$(get_tmux_option "@ai-status-busy-icon" "🤖")
idle_icon=$(get_tmux_option "@ai-status-idle-icon" "💤")
waiting_icon=$(get_tmux_option "@ai-status-waiting-icon" "⏳")
error_icon=$(get_tmux_option "@ai-status-error-icon" "❗")
colors_config=$(get_tmux_option "@ai-status-colors" "claude:colour135,opencode:colour82,aider:colour220,copilot:colour75")
capture_lines=$(get_tmux_option "@ai-status-capture-lines" "15")

idle_color="colour245"
waiting_color="colour220"
error_color="colour196"

# --- Get active pane info ---
pane_id=$(tmux display-message -p '#{pane_id}' 2>/dev/null)
pane_pid="${1:-$(tmux display-message -p '#{pane_pid}' 2>/dev/null)}"
[ -z "$pane_pid" ] && exit 0

# --- Color lookup ---
get_tool_color() {
    _tool_name="$1"
    _old_ifs="$IFS"
    IFS=','
    for _entry in $colors_config; do
        _key="${_entry%%:*}"
        _val="${_entry#*:}"
        if [ "$_key" = "$_tool_name" ]; then
            IFS="$_old_ifs"
            echo "$_val"
            return
        fi
    done
    IFS="$_old_ifs"
    echo "colour244"
}

# --- State detection via terminal content scraping ---
# Priority: error > waiting > busy > idle
# Checks the last N lines of pane output for known TUI patterns
detect_state() {
    _content="$1"
    [ -z "$_content" ] && echo "idle" && return

    # Error: tool hit an error state
    if printf '%s' "$_content" | grep -qE '(✗|✘)'; then
        echo "error"
        return
    fi
    if printf '%s' "$_content" | grep -qiE '(\berror:\s|^ERROR[ :]|fatal error|panic:|unhandled exception)'; then
        echo "error"
        return
    fi

    # Waiting: tool needs user permission or confirmation
    if printf '%s' "$_content" | grep -qiE '(\[Y/n\]|\[y/N\]|\[y/n\]|y/n\))'; then
        echo "waiting"
        return
    fi
    if printf '%s' "$_content" | grep -qiE '(Allow|Deny|always allow|approve this|confirm\?|Continue\?|permission)'; then
        echo "waiting"
        return
    fi

    # Busy: AI is actively thinking, generating, or using tools
    # Braille spinner characters (used by many TUI tools)
    if printf '%s' "$_content" | grep -qE '[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏⣾⣽⣻⢿⡿⣟⣯⣷]'; then
        echo "busy"
        return
    fi
    # Circle spinners
    if printf '%s' "$_content" | grep -qE '[◐◓◑◒]'; then
        echo "busy"
        return
    fi
    # Thinking / working indicators
    if printf '%s' "$_content" | grep -qiE '(Thinking|Generating|Streaming|Reasoning)'; then
        echo "busy"
        return
    fi
    # Tool use indicators (Claude Code, OpenCode)
    if printf '%s' "$_content" | grep -qE '(Tool:|Running tool|Reading |Writing |Editing |Searching |Creating )'; then
        echo "busy"
        return
    fi
    # Progress dots at end of line
    if printf '%s' "$_content" | grep -qE '\.\.\.[[:space:]]*$'; then
        echo "busy"
        return
    fi

    echo "idle"
}

# --- Format output based on state ---
format_status() {
    _tool="$1"
    _state="$2"
    _tool_color=$(get_tool_color "$_tool")

    case "$_state" in
        error)
            printf '#[fg=%s]%s %s#[default] ' "$error_color" "$error_icon" "$_tool"
            ;;
        waiting)
            printf '#[fg=%s]%s %s#[default] ' "$waiting_color" "$waiting_icon" "$_tool"
            ;;
        busy)
            printf '#[fg=%s]%s %s#[default] ' "$_tool_color" "$busy_icon" "$_tool"
            ;;
        idle)
            printf '#[fg=%s]%s %s#[default] ' "$idle_color" "$idle_icon" "$_tool"
            ;;
    esac
}

# --- Process tree scan ---
# Single ps call to snapshot all processes
proc_snapshot=$(ps -eo pid=,ppid=,args= 2>/dev/null) || exit 0

# Single awk pass: BFS from pane_pid to collect all descendant args
desc_args=$(printf '%s\n' "$proc_snapshot" | awk -v root="$pane_pid" '
{
    gsub(/^[[:space:]]+/, "")
    pid = $1 + 0
    ppid = $2 + 0
    a = ""
    for (i = 3; i <= NF; i++) a = a (i > 3 ? " " : "") $i
    p[NR] = pid
    pp[NR] = ppid
    ar[NR] = a
    n = NR
}
END {
    q[root + 0] = 1
    changed = 1
    while (changed) {
        changed = 0
        for (i = 1; i <= n; i++) {
            if ((pp[i] in q) && !(p[i] in q)) {
                q[p[i]] = 1
                changed = 1
            }
        }
    }
    for (i = 1; i <= n; i++) {
        if ((p[i] in q) && p[i] != (root + 0))
            print ar[i]
    }
}')

[ -z "$desc_args" ] && exit 0

# --- Match tools and detect state ---
_saved_ifs="$IFS"
IFS=','
for tool in $tools; do
    tool=$(printf '%s' "$tool" | tr -d ' ')
    if printf '%s\n' "$desc_args" | grep -q "$tool"; then
        IFS="$_saved_ifs"

        # Capture terminal content for state detection
        content=""
        if [ -n "$pane_id" ]; then
            content=$(tmux capture-pane -p -t "$pane_id" -S -"$capture_lines" 2>/dev/null)
        fi

        state=$(detect_state "$content")
        format_status "$tool" "$state"
        exit 0
    fi
done
IFS="$_saved_ifs"
