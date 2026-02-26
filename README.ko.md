# tmux-ai-status

[English](README.md) | **한국어**

tmux 상태바에 AI 코딩 도구(Claude Code, OpenCode, Aider, Copilot) 상태를 표시하는 플러그인입니다.

## 설치

### TPM

```tmux
set -g @plugin 'dding-g/tmux-ai-status'
```

`prefix + I`로 설치.

### 수동 설치

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
    rtpFilePath = "ai-status.tmux";  # 필수 — 없으면 Nix가 ai_status.tmux를 찾음
    version = "0.1.0";
    src = pkgs.fetchFromGitHub {
      owner = "dding-g";
      repo = "tmux-ai-status";
      rev = "main";
      hash = "";  # 첫 빌드 시 에러 메시지에서 올바른 해시 확인
    };
  };
}
```

## 사용법

### 상태바 모드 (`ai-status.sh`)

`status-right`에 AI 도구 상태를 자동 표시합니다. 터미널 내용 스크래핑으로 4가지 상태 감지:

| 상태 | 표시 | 의미 |
|------|------|------|
| busy | `🤖 claude` | AI가 생각하거나 도구 사용 중 |
| waiting | `⏳ claude` | 사용자 권한 확인 대기 |
| error | `❗ claude` | 에러 발생 |
| idle | `💤 claude` | 입력 대기 |

`#{ai_status}` 플레이스홀더로 위치 지정:

```tmux
set -g status-right '#{ai_status} | %H:%M'
```

### 윈도우별 아이콘 모드 (`ai-icon.sh`)

각 윈도우 탭에 아이콘을 표시합니다. 터미널 스크래핑 대신 프로세스 CPU 활동으로 감지하여 "작업 중"과 "대기 중"을 안정적으로 구분합니다.

```tmux
# 일반 tmux
set -g window-status-format         '#I:#W#(~/.tmux/plugins/tmux-ai-status/scripts/ai-icon.sh #{pane_pid} #{pane_id})'
set -g window-status-current-format '#I:#W#(~/.tmux/plugins/tmux-ai-status/scripts/ai-icon.sh #{pane_pid} #{pane_id})'

# catppuccin
set -g @catppuccin_window_default_text " #W#($PLUGIN_DIR/scripts/ai-icon.sh #{pane_pid} #{pane_id})"
set -g @catppuccin_window_current_text " #W#($PLUGIN_DIR/scripts/ai-icon.sh #{pane_pid} #{pane_id})"
```

| 상태 | 아이콘 |
|------|--------|
| busy | 🤖 |
| idle | 💤 |

## 설정

모든 옵션은 `~/.tmux.conf`에 설정합니다. 아래는 기본값입니다.

```tmux
set -g @ai-status-tools "claude,opencode,aider,copilot"
set -g @ai-status-position "right"
set -g @ai-status-interval 5

# 아이콘
set -g @ai-status-busy-icon "🤖"
set -g @ai-status-idle-icon "💤"
set -g @ai-status-waiting-icon "⏳"
set -g @ai-status-error-icon "❗"

# 상태 감지를 위해 스캔할 터미널 줄 수
set -g @ai-status-capture-lines "15"

# 도구별 색상 (도구:색상)
set -g @ai-status-colors "claude:colour135,opencode:colour82,aider:colour220,copilot:colour75"
```

## 라이선스

[MIT](LICENSE)
