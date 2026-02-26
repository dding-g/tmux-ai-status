# tmux-ai-status

**English** | [한국어](README.ko.md)

Tmux plugin that shows AI coding tool status (Claude Code, OpenCode, Aider, Copilot) in your status bar.

## Installation

### TPM

```tmux
set -g @plugin 'dding-g/tmux-ai-status'
```

Press `prefix + I` to install.

### Manual

```sh
git clone https://github.com/dding-g/tmux-ai-status ~/.tmux/plugins/tmux-ai-status
```

```tmux
# ~/.tmux.conf
run-shell ~/.tmux/plugins/tmux-ai-status/ai-status.tmux
```

### Nix (home-manager)

```nix
{
  plugin = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "ai-status";
    rtpFilePath = "ai-status.tmux";  # required — without this, Nix looks for ai_status.tmux
    version = "0.1.0";
    src = pkgs.fetchFromGitHub {
      owner = "dding-g";
      repo = "tmux-ai-status";
      rev = "main";
      hash = "";  # first build will show the correct hash
    };
  };
}
```

## Usage

### Status bar mode (`ai-status.sh`)

Automatically shows AI tool status in `status-right`. Detects 4 states via terminal content scraping:

| State | Display | Meaning |
|-------|---------|---------|
| busy | `🤖 claude` | AI is thinking or using tools |
| waiting | `⏳ claude` | Needs your permission |
| error | `❗ claude` | Error occurred |
| idle | `💤 claude` | Waiting for input |

Place it manually with the `#{ai_status}` placeholder:

```tmux
set -g status-right '#{ai_status} | %H:%M'
```

### Per-window icon mode (`ai-icon.sh`)

Shows an icon per window tab. Uses process CPU activity instead of terminal scraping — reliably distinguishes "working" from "idle".

```tmux
# plain tmux
set -g window-status-format         '#I:#W#(~/.tmux/plugins/tmux-ai-status/scripts/ai-icon.sh #{pane_pid} #{pane_id})'
set -g window-status-current-format '#I:#W#(~/.tmux/plugins/tmux-ai-status/scripts/ai-icon.sh #{pane_pid} #{pane_id})'

# catppuccin
set -g @catppuccin_window_default_text " #W#($PLUGIN_DIR/scripts/ai-icon.sh #{pane_pid} #{pane_id})"
set -g @catppuccin_window_current_text " #W#($PLUGIN_DIR/scripts/ai-icon.sh #{pane_pid} #{pane_id})"
```

| State | Icon |
|-------|------|
| busy | 🤖 |
| idle | 💤 |

## Configuration

All options go in `~/.tmux.conf`. Defaults shown below.

```tmux
set -g @ai-status-tools "claude,opencode,aider,copilot"
set -g @ai-status-position "right"
set -g @ai-status-interval 5

# icons
set -g @ai-status-busy-icon "🤖"
set -g @ai-status-idle-icon "💤"
set -g @ai-status-waiting-icon "⏳"
set -g @ai-status-error-icon "❗"

# terminal lines to scan for state detection
set -g @ai-status-capture-lines "15"

# per-tool colors (tool:colour)
set -g @ai-status-colors "claude:colour135,opencode:colour82,aider:colour220,copilot:colour75"
```

## License

[MIT](LICENSE)
