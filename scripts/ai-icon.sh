#!/usr/bin/env sh
# ai-icon.sh - Lightweight per-window AI status icon
# Outputs a single icon based on the AI tool state in a specific pane.
# Designed to be called from window-status-format, so it receives
# pane_pid and pane_id as CLI arguments (no tmux option reads for performance).
#
# Usage in tmux:
#   set -g window-status-format '#I:#W#(path/to/ai-icon.sh #{pane_pid} #{pane_id})'
#
# POSIX sh compatible

pane_pid="$1"
pane_id="$2"

[ -z "$pane_pid" ] && exit 0

# --- Icons (no color, no tool name — just a single icon) ---
busy_icon=" 🤖"
idle_icon=" 💤"
waiting_icon=" ⏳"
error_icon=" ❗"

# --- State detection via terminal content scraping ---
# Same priority as ai-status.sh: error > waiting > busy > idle
detect_state() {
    _content="$1"
    [ -z "$_content" ] && echo "idle" && return

    # Error
    if printf '%s' "$_content" | /usr/bin/grep -qE '(✗|✘)'; then
        echo "error"; return
    fi
    if printf '%s' "$_content" | /usr/bin/grep -qiE '(\berror:\s|^ERROR[ :]|fatal error|panic:|unhandled exception)'; then
        echo "error"; return
    fi

    # Waiting
    if printf '%s' "$_content" | /usr/bin/grep -qiE '(\[Y/n\]|\[y/N\]|\[y/n\]|y/n\))'; then
        echo "waiting"; return
    fi
    if printf '%s' "$_content" | /usr/bin/grep -qiE '(Allow|Deny|always allow|approve this|confirm\?|Continue\?|permission)'; then
        echo "waiting"; return
    fi

    # Busy — spinners
    if printf '%s' "$_content" | /usr/bin/grep -qE '[⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏⣾⣽⣻⢿⡿⣟⣯⣷]'; then
        echo "busy"; return
    fi
    if printf '%s' "$_content" | /usr/bin/grep -qE '[◐◓◑◒]'; then
        echo "busy"; return
    fi
    # Thinking / working indicators
    if printf '%s' "$_content" | /usr/bin/grep -qiE '(Thinking|Generating|Streaming|Reasoning)'; then
        echo "busy"; return
    fi
    # Tool use indicators
    if printf '%s' "$_content" | /usr/bin/grep -qE '(Tool:|Running tool|Reading |Writing |Editing |Searching |Creating )'; then
        echo "busy"; return
    fi
    # Progress dots
    if printf '%s' "$_content" | /usr/bin/grep -qE '\.\.\.[[:space:]]*$'; then
        echo "busy"; return
    fi

    echo "idle"
}

# --- Process tree scan ---
proc_snapshot=$(ps -eo pid=,ppid=,args= 2>/dev/null) || exit 0

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

# --- Check if any known AI tool is running ---
tools="claude opencode aider copilot"
found=""
for tool in $tools; do
    if printf '%s\n' "$desc_args" | /usr/bin/grep -q "$tool"; then
        found="$tool"
        break
    fi
done

[ -z "$found" ] && exit 0

# --- Capture terminal content and detect state ---
content=""
if [ -n "$pane_id" ]; then
    content=$(tmux capture-pane -p -t "$pane_id" -S -15 2>/dev/null)
fi

state=$(detect_state "$content")

case "$state" in
    error)   printf '%s' "$error_icon" ;;
    waiting) printf '%s' "$waiting_icon" ;;
    busy)    printf '%s' "$busy_icon" ;;
    idle)    printf '%s' "$idle_icon" ;;
esac
