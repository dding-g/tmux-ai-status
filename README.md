# tmux-ai-status

Tmux plugin that detects AI coding tools (Claude Code, OpenCode, Aider, Copilot) running in the active pane and displays their status in the tmux status bar.

## Features

- Detects AI coding tools by scanning the active pane's process tree
- **4-state activity detection** via terminal content scraping (`tmux capture-pane`)
  - **busy**: AI is thinking, generating, or using tools (spinner/keywords detected)
  - **waiting**: AI needs user permission or confirmation
  - **error**: tool encountered an error
  - **idle**: waiting for user input
- Supports Claude Code, OpenCode, Aider, and GitHub Copilot out of the box
- Extensible: add custom tools via configuration
- Works on both macOS and Linux
- POSIX sh compatible, no bash dependency
- Lightweight: single `ps` call + `tmux capture-pane`

## Installation

### With [TPM](https://github.com/tmux-plugins/tpm) (recommended)

Add to your `~/.tmux.conf`:

```tmux
set -g @plugin 'dding-g/tmux-ai-status'
```

Then press `prefix + I` to install.

### Manual

```sh
git clone https://github.com/dding-g/tmux-ai-status ~/.tmux/plugins/tmux-ai-status
```

Add to your `~/.tmux.conf`:

```tmux
run-shell ~/.tmux/plugins/tmux-ai-status/ai-status.tmux
```

Reload tmux:

```sh
tmux source-file ~/.tmux.conf
```

## Usage

Once installed, the plugin automatically prepends AI tool status to your `status-right`:

| State | Display | Meaning |
|-------|---------|---------|
| **busy** | `🤖 claude` (colored) | AI is thinking or generating a response |
| **waiting** | `⏳ claude` (yellow) | AI needs your permission/confirmation |
| **error** | `❗ claude` (red) | Tool encountered an error |
| **idle** | `💤 claude` (grey) | Conversation ended, waiting for input |
| *not running* | *(nothing)* | No AI tool detected |

### Using the `#{ai_status}` placeholder

For precise control over placement, add `#{ai_status}` to your status string:

```tmux
set -g status-right '#{ai_status} | %H:%M'
```

The plugin replaces `#{ai_status}` with the detection output. If no placeholder is found, the plugin prepends to the status bar automatically.

## Configuration

All options are set via `tmux set -g @option value` in `~/.tmux.conf`.

### `@ai-status-tools`

Comma-separated list of tool names to detect.

```tmux
set -g @ai-status-tools "claude,opencode,aider,copilot"  # default
```

### `@ai-status-position`

Which side of the status bar to use: `right` or `left`.

```tmux
set -g @ai-status-position "right"  # default
```

### `@ai-status-interval`

Status refresh interval in seconds.

```tmux
set -g @ai-status-interval 5  # default
```

Note: this sets `status-interval` globally. The plugin only lowers it, never raises it.

### State icons

Each state has its own icon:

```tmux
set -g @ai-status-busy-icon "🤖"     # default, shown when AI is working
set -g @ai-status-idle-icon "💤"     # shown when waiting for user input
set -g @ai-status-waiting-icon "⏳"  # shown when AI needs permission
set -g @ai-status-error-icon "❗"    # shown when tool has an error
```

### `@ai-status-capture-lines`

Number of terminal lines to scan for state detection.

```tmux
set -g @ai-status-capture-lines "15"  # default
```

### `@ai-status-colors`

Tool-specific tmux colors, formatted as `tool:colour,tool:colour`.

```tmux
set -g @ai-status-colors "claude:colour135,opencode:colour82,aider:colour220,copilot:colour75"  # default
```

Default color mapping:
| Tool | Color | Appearance |
|------|-------|------------|
| claude | colour135 | Purple |
| opencode | colour82 | Green |
| aider | colour220 | Yellow |
| copilot | colour75 | Blue |

State colors (not configurable):
| State | Color |
|-------|-------|
| busy | tool's own color |
| idle | colour245 (grey) |
| waiting | colour220 (yellow) |
| error | colour196 (red) |

## Example configurations

### Minimal

```tmux
set -g @plugin 'dding-g/tmux-ai-status'
```

### Custom icons

```tmux
set -g @plugin 'dding-g/tmux-ai-status'
set -g @ai-status-busy-icon "⚡"
set -g @ai-status-idle-icon "○"
set -g @ai-status-waiting-icon "◉"
set -g @ai-status-error-icon "✗"
```

### Only detect Claude and Aider

```tmux
set -g @plugin 'dding-g/tmux-ai-status'
set -g @ai-status-tools "claude,aider"
```

### Left side with faster refresh

```tmux
set -g @plugin 'dding-g/tmux-ai-status'
set -g @ai-status-position "left"
set -g @ai-status-interval 3
```

## How it works

1. The plugin registers a shell command (`#(...)`) in your tmux status bar
2. Every `@ai-status-interval` seconds, tmux runs the detection script
3. The script gets the active pane's PID and pane ID via `tmux display-message`
4. A single `ps -eo pid=,ppid=,args=` call snapshots all processes
5. An awk-based BFS walks the process tree from the pane PID
6. Descendant process args are checked against the configured tool list
7. If a tool is found, `tmux capture-pane` reads the last N lines of terminal content
8. Pattern matching determines the state:

| Priority | State | Detection patterns |
|----------|-------|--------------------|
| 1 | error | `✗`, `✘`, `error:`, `fatal error`, `panic:` |
| 2 | waiting | `[Y/n]`, `[y/N]`, `Allow`, `Deny`, `always allow`, `Continue?` |
| 3 | busy | Braille spinners (`⠋⠙⠹...`), circle spinners (`◐◓◑◒`), `Thinking`, `Generating`, `Tool:`, `Reading`, `Writing`, `Editing`, trailing `...` |
| 4 | idle | Default (no pattern matched) |

## Troubleshooting

### Not detecting a tool

Verify the tool appears in the pane's process tree:

```sh
# Get pane PID
tmux display-message -p '#{pane_pid}'

# Check descendants (replace PID)
ps -eo pid=,ppid=,args= | awk -v root=PID '...'
```

Or run the detection script manually:

```sh
~/.tmux/plugins/tmux-ai-status/scripts/ai-status.sh
```

### State always shows idle

The state detection relies on reading the terminal content. If patterns aren't matching:

1. Check what your pane shows: `tmux capture-pane -p -t <pane_id> -S -15`
2. Increase capture depth: `set -g @ai-status-capture-lines "30"`
3. The tool's TUI might use different indicators than expected

### Adding a custom tool

Add the process name to `@ai-status-tools` and optionally a color:

```tmux
set -g @ai-status-tools "claude,opencode,aider,copilot,cursor"
set -g @ai-status-colors "claude:colour135,opencode:colour82,aider:colour220,copilot:colour75,cursor:colour208"
```

## Requirements

- tmux 2.1+
- POSIX-compatible shell (`sh`, `dash`, `bash`, `zsh`)
- `ps` and `awk` (available on all Unix systems)

## License

[MIT](LICENSE)
