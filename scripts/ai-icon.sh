#!/usr/bin/env sh
# ai-icon.sh - Lightweight per-window AI status icon
# Outputs a single icon based on AI tool process activity.
# Uses process state (R=running) and CPU usage instead of terminal scraping,
# so it reliably distinguishes "in progress" from "idle" without capture-pane.
#
# Usage in tmux:
#   set -g window-status-format '#I:#W#(path/to/ai-icon.sh #{pane_pid} #{pane_id})'
#
# POSIX sh compatible

pane_pid="$1"
# pane_id=$2 is accepted for CLI compatibility but not used (no capture-pane)

[ -z "$pane_pid" ] && exit 0

# --- Icons ---
busy_icon=" 🤖"
idle_icon=" 💤"

# --- Single ps call with state + CPU columns ---
proc_snapshot=$(ps -eo pid=,ppid=,state=,pcpu=,args= 2>/dev/null) || exit 0

# --- Single awk pass: BFS descendants, find tool, check activity ---
result=$(printf '%s\n' "$proc_snapshot" | awk -v root="$pane_pid" '
{
    gsub(/^[[:space:]]+/, "")
    pid  = $1 + 0
    ppid = $2 + 0
    st   = $3
    cpu  = $4 + 0.0
    a = ""
    for (i = 5; i <= NF; i++) a = a (i > 5 ? " " : "") $i

    p[NR]    = pid
    pp[NR]   = ppid
    state[NR]= st
    pcpu[NR] = cpu
    args[NR] = a
    n = NR
}
END {
    # BFS: collect all descendants of pane_pid
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

    # Check if any descendant matches a known AI tool
    found = 0
    split("claude opencode aider copilot", tools, " ")
    for (i = 1; i <= n; i++) {
        if (!(p[i] in q) || p[i] == (root + 0)) continue
        for (j in tools) {
            if (index(args[i], tools[j]) > 0) {
                found = 1
                break
            }
        }
        if (found) break
    }
    if (!found) { print "none"; exit }

    # Check if any descendant is actively running (R state or CPU > 1%)
    for (i = 1; i <= n; i++) {
        if (!(p[i] in q) || p[i] == (root + 0)) continue
        if (substr(state[i], 1, 1) == "R" || pcpu[i] > 1.0) {
            print "busy"
            exit
        }
    }
    print "idle"
}')

case "$result" in
    busy) printf '%s' "$busy_icon" ;;
    idle) printf '%s' "$idle_icon" ;;
esac
