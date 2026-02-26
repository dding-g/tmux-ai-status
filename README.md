# tmux-ai-status

**English** | [한국어](README.ko.md)

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

### For Humans

Copy and paste this into your `~/.tmux.conf`:

```tmux
set -g @plugin 'dding-g/tmux-ai-status'
```

Then press `prefix + I` to install. Done.

### For LLM Agents

Copy the prompt below and paste it into your AI agent (Claude Code, Cursor, etc.):

<details>
<summary>Click to expand full prompt</summary>

```
Install the tmux-ai-status plugin. This is a TPM-compatible tmux plugin that detects AI coding tools (Claude Code, OpenCode, Aider, Copilot) running in the active pane and shows their status in the tmux status bar.

Repository: https://github.com/dding-g/tmux-ai-status

## Installation Steps

1. Clone the plugin:
   git clone https://github.com/dding-g/tmux-ai-status ~/.tmux/plugins/tmux-ai-status

2. Add to tmux config (~/.tmux.conf or ~/.config/tmux/tmux.conf):
   - If using TPM: set -g @plugin 'dding-g/tmux-ai-status'
   - If manual: run-shell ~/.tmux/plugins/tmux-ai-status/ai-status.tmux

3. If using Nix home-manager, add to programs.tmux.plugins:
   {
     plugin = pkgs.tmuxPlugins.mkTmuxPlugin {
       pluginName = "ai-status";
       rtpFilePath = "ai-status.tmux";
       version = "0.1.0";
       src = pkgs.fetchFromGitHub {
         owner = "dding-g";
         repo = "tmux-ai-status";
         rev = "main";
         hash = "";
       };
     };
   }

4. Reload: tmux source-file ~/.tmux.conf

## Available Options (all optional)

set -g @ai-status-tools "claude,opencode,aider,copilot"  # tools to detect
set -g @ai-status-position "right"                        # right or left
set -g @ai-status-interval 5                              # refresh seconds
set -g @ai-status-busy-icon "🤖"                          # AI working
set -g @ai-status-idle-icon "💤"                          # waiting for input
set -g @ai-status-waiting-icon "⏳"                       # needs permission
set -g @ai-status-error-icon "❗"                         # error state
set -g @ai-status-capture-lines "15"                      # terminal lines to scan
set -g @ai-status-colors "claude:colour135,opencode:colour82,aider:colour220,copilot:colour75"

## How It Works

The plugin scans the active pane's process tree (ps + awk BFS), then reads the last N lines of terminal content via tmux capture-pane to determine 4 states:
- busy: spinner characters, "Thinking", "Tool:", "Reading", "Writing"
- waiting: [Y/n], Allow, Deny, Continue?
- error: ✗, error:, fatal, panic:
- idle: no pattern matched (default)

Detect the user's tmux setup (TPM vs manual vs Nix) and apply the appropriate method.
```

</details>

---

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

### Nix (home-manager)

#### Option A: As a plugin

Add to your `programs.tmux.plugins` in your tmux module:

```nix
{
  plugin = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "ai-status";
    rtpFilePath = "ai-status.tmux";
    version = "0.1.0";
    src = pkgs.fetchFromGitHub {
      owner = "dding-g";
      repo = "tmux-ai-status";
      rev = "main";
      hash = "";  # first build will show the correct hash
    };
  };
  extraConfig = ''
    set -g @ai-status-tools "claude,opencode,aider,copilot"
  '';
}
```

> **Important:** `rtpFilePath = "ai-status.tmux"` is required. Without it, `mkTmuxPlugin` converts hyphens to underscores and looks for `ai_status.tmux`, which doesn't exist.

#### Option B: In extraConfig

Add to `programs.tmux.extraConfig`:

```nix
extraConfig = ''
  # ... your existing config ...

  # ai-status plugin
  run-shell ${pkgs.fetchFromGitHub {
    owner = "dding-g";
    repo = "tmux-ai-status";
    rev = "main";
    hash = "";  # first build will show the correct hash
  }}/ai-status.tmux
'';
```

> **Note:** On first build, Nix will error with the correct `hash` value. Replace the empty string with that value.

Then rebuild:

```sh
# NixOS
sudo nixos-rebuild switch

# nix-darwin
darwin-rebuild switch --flake .

# home-manager standalone
home-manager switch
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

### Per-window icon mode

The main `ai-status.sh` shows status for the **active pane** in `status-right`/`status-left`. If you run AI tools in multiple windows simultaneously, you can use `ai-icon.sh` to display a per-window icon in each tab.

`ai-icon.sh` is a lightweight, standalone script:
- Receives `pane_pid` and `pane_id` as CLI arguments (no tmux option reads)
- Detects activity via **process state** (CPU usage), not terminal content scraping
- Outputs a single icon with no color or tool name (suitable for tab labels)
- Two states: **busy** (AI is actively working) vs **idle** (waiting for input)

#### With catppuccin

```tmux
set -g @catppuccin_window_default_text " #W#($PLUGIN_DIR/scripts/ai-icon.sh #{pane_pid} #{pane_id})"
set -g @catppuccin_window_current_text " #W#($PLUGIN_DIR/scripts/ai-icon.sh #{pane_pid} #{pane_id})"
```

> Replace `$PLUGIN_DIR` with your actual plugin path, e.g. `~/.tmux/plugins/tmux-ai-status`.

#### With plain tmux

```tmux
set -g window-status-format         '#I:#W#(~/.tmux/plugins/tmux-ai-status/scripts/ai-icon.sh #{pane_pid} #{pane_id})'
set -g window-status-current-format '#I:#W#(~/.tmux/plugins/tmux-ai-status/scripts/ai-icon.sh #{pane_pid} #{pane_id})'
```

| State | Icon |
|-------|------|
| busy | 🤖 |
| idle | 💤 |
| not running | *(empty)* |

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
