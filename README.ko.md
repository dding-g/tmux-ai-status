# tmux-ai-status

[English](README.md) | **한국어**

현재 tmux pane에서 실행 중인 AI 코딩 도구(Claude Code, OpenCode, Aider, Copilot)를 감지하여 상태바에 표시하는 tmux 플러그인입니다.

## 주요 기능

- 활성 pane의 프로세스 트리를 스캔하여 AI 도구 감지
- **4단계 상태 감지** - 터미널 내용 스크래핑(`tmux capture-pane`) 기반
  - **busy**: AI가 생각하거나 응답을 생성 중 (스피너/키워드 감지)
  - **waiting**: 사용자 권한 확인 또는 승인 대기
  - **error**: 도구에서 에러 발생
  - **idle**: 대화 종료, 사용자 입력 대기
- Claude Code, OpenCode, Aider, GitHub Copilot 기본 지원
- 설정으로 커스텀 도구 추가 가능
- macOS, Linux 모두 지원
- POSIX sh 호환 (bash 의존성 없음)
- 가벼움: `ps` 호출 1회 + `tmux capture-pane`

## 설치

### 사람용

`~/.tmux.conf`에 복사 붙여넣기:

```tmux
set -g @plugin 'dding-g/tmux-ai-status'
```

`prefix + I`로 설치. 끝.

### AI 에이전트용

아래 프롬프트를 AI 에이전트(Claude Code, Cursor 등)에 복사 붙여넣기하세요:

<details>
<summary>프롬프트 전문 보기</summary>

```
tmux-ai-status 플러그인을 설치해줘. 이 플러그인은 tmux 활성 pane에서 실행 중인 AI 코딩 도구(Claude Code, OpenCode, Aider, Copilot)를 감지하여 상태바에 표시하는 TPM 호환 플러그인이야.

레포지토리: https://github.com/dding-g/tmux-ai-status

## 설치 순서

1. 플러그인 클론:
   git clone https://github.com/dding-g/tmux-ai-status ~/.tmux/plugins/tmux-ai-status

2. tmux 설정 파일(~/.tmux.conf 또는 ~/.config/tmux/tmux.conf)에 추가:
   - TPM 사용 시: set -g @plugin 'dding-g/tmux-ai-status'
   - 수동 설치: run-shell ~/.tmux/plugins/tmux-ai-status/ai-status.tmux

3. Nix home-manager 사용 시 programs.tmux.plugins에 추가:
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

4. 리로드: tmux source-file ~/.tmux.conf

## 설정 옵션 (모두 선택사항)

set -g @ai-status-tools "claude,opencode,aider,copilot"  # 감지할 도구
set -g @ai-status-position "right"                        # right 또는 left
set -g @ai-status-interval 5                              # 갱신 주기 (초)
set -g @ai-status-busy-icon "🤖"                          # AI 작업 중
set -g @ai-status-idle-icon "💤"                          # 입력 대기
set -g @ai-status-waiting-icon "⏳"                       # 권한 확인 대기
set -g @ai-status-error-icon "❗"                         # 에러 발생
set -g @ai-status-capture-lines "15"                      # 스캔할 터미널 줄 수
set -g @ai-status-colors "claude:colour135,opencode:colour82,aider:colour220,copilot:colour75"

## 동작 원리

이 플러그인은 활성 pane의 프로세스 트리를 스캔(ps + awk BFS)한 후, tmux capture-pane으로 터미널 마지막 N줄을 읽어 4가지 상태를 판별해:
- busy: 스피너 문자, "Thinking", "Tool:", "Reading", "Writing"
- waiting: [Y/n], Allow, Deny, Continue?
- error: ✗, error:, fatal, panic:
- idle: 패턴 매칭 없음 (기본값)

사용자의 tmux 환경(TPM / 수동 / Nix)을 감지하여 적절한 방법으로 설치해줘.
```

</details>

---

### 수동 설치

```sh
git clone https://github.com/dding-g/tmux-ai-status ~/.tmux/plugins/tmux-ai-status
```

`~/.tmux.conf`에 추가:

```tmux
run-shell ~/.tmux/plugins/tmux-ai-status/ai-status.tmux
```

tmux 리로드:

```sh
tmux source-file ~/.tmux.conf
```

### Nix (home-manager)

#### 방법 A: 플러그인으로 추가

tmux 모듈의 `programs.tmux.plugins`에 추가:

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
      hash = "";  # 첫 빌드 시 에러 메시지에서 올바른 해시 확인
    };
  };
  extraConfig = ''
    set -g @ai-status-tools "claude,opencode,aider,copilot"
  '';
}
```

> **중요:** `rtpFilePath = "ai-status.tmux"`가 필수입니다. 이 설정이 없으면 `mkTmuxPlugin`이 하이픈을 언더스코어로 변환하여 존재하지 않는 `ai_status.tmux`를 찾습니다.

#### 방법 B: extraConfig에서 직접 로드

`programs.tmux.extraConfig`에 추가:

```nix
extraConfig = ''
  # ... 기존 설정 ...

  # ai-status 플러그인
  run-shell ${pkgs.fetchFromGitHub {
    owner = "dding-g";
    repo = "tmux-ai-status";
    rev = "main";
    hash = "";  # 첫 빌드 시 에러 메시지에서 올바른 해시 확인
  }}/ai-status.tmux
'';
```

> **참고:** 첫 빌드 시 Nix가 올바른 `hash` 값을 에러 메시지로 알려줍니다. 빈 문자열을 해당 값으로 교체하세요.

리빌드:

```sh
# NixOS
sudo nixos-rebuild switch

# nix-darwin
darwin-rebuild switch --flake .

# home-manager 단독
home-manager switch
```

## 사용법

설치하면 자동으로 `status-right`에 AI 도구 상태가 표시됩니다:

| 상태 | 표시 | 의미 |
|------|------|------|
| **busy** | `🤖 claude` (도구 색상) | AI가 생각하거나 응답 생성 중 |
| **waiting** | `⏳ claude` (노랑) | 사용자 권한/승인 대기 |
| **error** | `❗ claude` (빨강) | 에러 발생 |
| **idle** | `💤 claude` (회색) | 대화 종료, 입력 대기 |
| *미실행* | *(빈 문자열)* | AI 도구 미감지 |

### `#{ai_status}` 플레이스홀더

위치를 직접 지정하려면 상태 문자열에 `#{ai_status}`를 추가:

```tmux
set -g status-right '#{ai_status} | %H:%M'
```

플레이스홀더가 없으면 자동으로 상태바 앞에 prepend됩니다.

### 윈도우별 아이콘 모드

기본 `ai-status.sh`는 **활성 pane**의 상태를 `status-right`/`status-left`에 표시합니다. 여러 윈도우에서 동시에 AI 도구를 실행하면 각 탭에 개별 아이콘을 표시할 수 있는 `ai-icon.sh`를 사용하세요.

`ai-icon.sh`는 경량 독립 스크립트입니다:
- `pane_pid`와 `pane_id`를 CLI 인자로 수신 (tmux option 읽기 없음)
- 터미널 내용 스크래핑 대신 **프로세스 상태**(CPU 사용량)로 활동 감지
- 색상이나 도구명 없이 아이콘만 출력 (탭 라벨에 적합)
- 두 가지 상태: **busy** (AI 작업 중) vs **idle** (입력 대기)

#### catppuccin 연동

```tmux
set -g @catppuccin_window_default_text " #W#($PLUGIN_DIR/scripts/ai-icon.sh #{pane_pid} #{pane_id})"
set -g @catppuccin_window_current_text " #W#($PLUGIN_DIR/scripts/ai-icon.sh #{pane_pid} #{pane_id})"
```

> `$PLUGIN_DIR`을 실제 플러그인 경로로 교체하세요. 예: `~/.tmux/plugins/tmux-ai-status`

#### 일반 tmux

```tmux
set -g window-status-format         '#I:#W#(~/.tmux/plugins/tmux-ai-status/scripts/ai-icon.sh #{pane_pid} #{pane_id})'
set -g window-status-current-format '#I:#W#(~/.tmux/plugins/tmux-ai-status/scripts/ai-icon.sh #{pane_pid} #{pane_id})'
```

| 상태 | 아이콘 |
|------|--------|
| busy | 🤖 |
| idle | 💤 |
| 미실행 | *(빈 문자열)* |

## 설정

모든 옵션은 `~/.tmux.conf`에서 `tmux set -g @option value`로 설정합니다.

### `@ai-status-tools`

감지할 도구 목록 (쉼표 구분).

```tmux
set -g @ai-status-tools "claude,opencode,aider,copilot"  # 기본값
```

### `@ai-status-position`

상태바 위치: `right` 또는 `left`.

```tmux
set -g @ai-status-position "right"  # 기본값
```

### `@ai-status-interval`

상태 갱신 주기 (초).

```tmux
set -g @ai-status-interval 5  # 기본값
```

참고: `status-interval`을 전역으로 설정합니다. 기존 값보다 낮을 때만 변경합니다.

### 상태별 아이콘

각 상태마다 다른 아이콘:

```tmux
set -g @ai-status-busy-icon "🤖"     # AI 작업 중
set -g @ai-status-idle-icon "💤"     # 입력 대기
set -g @ai-status-waiting-icon "⏳"  # 권한 확인 대기
set -g @ai-status-error-icon "❗"    # 에러 발생
```

### `@ai-status-capture-lines`

상태 감지를 위해 스캔할 터미널 줄 수.

```tmux
set -g @ai-status-capture-lines "15"  # 기본값
```

### `@ai-status-colors`

도구별 tmux 색상. `도구:색상,도구:색상` 형식.

```tmux
set -g @ai-status-colors "claude:colour135,opencode:colour82,aider:colour220,copilot:colour75"  # 기본값
```

기본 색상 매핑:
| 도구 | 색상 | 외관 |
|------|------|------|
| claude | colour135 | 보라 |
| opencode | colour82 | 초록 |
| aider | colour220 | 노랑 |
| copilot | colour75 | 파랑 |

상태별 색상 (설정 불가):
| 상태 | 색상 |
|------|------|
| busy | 도구 고유 색상 |
| idle | colour245 (회색) |
| waiting | colour220 (노랑) |
| error | colour196 (빨강) |

## 설정 예시

### 최소 설정

```tmux
set -g @plugin 'dding-g/tmux-ai-status'
```

### 커스텀 아이콘

```tmux
set -g @plugin 'dding-g/tmux-ai-status'
set -g @ai-status-busy-icon "⚡"
set -g @ai-status-idle-icon "○"
set -g @ai-status-waiting-icon "◉"
set -g @ai-status-error-icon "✗"
```

### Claude와 Aider만 감지

```tmux
set -g @plugin 'dding-g/tmux-ai-status'
set -g @ai-status-tools "claude,aider"
```

### 왼쪽 상태바 + 빠른 갱신

```tmux
set -g @plugin 'dding-g/tmux-ai-status'
set -g @ai-status-position "left"
set -g @ai-status-interval 3
```

## 동작 원리

1. 플러그인이 tmux 상태바에 쉘 명령(`#(...)`)을 등록
2. `@ai-status-interval`초마다 tmux가 감지 스크립트 실행
3. `tmux display-message`로 활성 pane의 PID와 pane ID 획득
4. `ps -eo pid=,ppid=,args=` 한 번 호출로 전체 프로세스 스냅샷
5. awk 기반 BFS로 pane PID부터 프로세스 트리 탐색
6. 자식 프로세스의 args에서 설정된 도구 이름 매칭
7. 도구가 발견되면 `tmux capture-pane`으로 터미널 마지막 N줄 읽기
8. 패턴 매칭으로 상태 결정:

| 우선순위 | 상태 | 감지 패턴 |
|---------|------|----------|
| 1 | error | `✗`, `✘`, `error:`, `fatal error`, `panic:` |
| 2 | waiting | `[Y/n]`, `[y/N]`, `Allow`, `Deny`, `always allow`, `Continue?` |
| 3 | busy | 점자 스피너(`⠋⠙⠹...`), 원형 스피너(`◐◓◑◒`), `Thinking`, `Generating`, `Tool:`, `Reading`, `Writing`, `Editing`, 끝의 `...` |
| 4 | idle | 기본값 (패턴 매칭 없음) |

## 문제 해결

### 도구가 감지되지 않을 때

pane의 프로세스 트리에 도구가 있는지 확인:

```sh
# pane PID 확인
tmux display-message -p '#{pane_pid}'

# 자식 프로세스 확인 (PID를 교체)
ps -eo pid=,ppid=,args= | awk -v root=PID '...'
```

또는 감지 스크립트를 직접 실행:

```sh
~/.tmux/plugins/tmux-ai-status/scripts/ai-status.sh
```

### 항상 idle로 표시될 때

상태 감지는 터미널 내용을 읽어서 판단합니다. 패턴이 매칭되지 않는다면:

1. pane 내용 확인: `tmux capture-pane -p -t <pane_id> -S -15`
2. 스캔 범위 확대: `set -g @ai-status-capture-lines "30"`
3. 도구의 TUI가 예상과 다른 표시를 사용할 수 있음

### 커스텀 도구 추가

`@ai-status-tools`에 프로세스 이름을, `@ai-status-colors`에 색상을 추가:

```tmux
set -g @ai-status-tools "claude,opencode,aider,copilot,cursor"
set -g @ai-status-colors "claude:colour135,opencode:colour82,aider:colour220,copilot:colour75,cursor:colour208"
```

## 요구사항

- tmux 2.1+
- POSIX 호환 쉘 (`sh`, `dash`, `bash`, `zsh`)
- `ps`, `awk` (모든 Unix 시스템에 기본 포함)

## 라이선스

[MIT](LICENSE)
