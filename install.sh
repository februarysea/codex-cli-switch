#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="$SCRIPT_DIR/bin/codex-switch"
INSTALL_DIR="${CODEX_SWITCH_INSTALL_DIR:-$HOME/.local/bin}"
TARGET_SCRIPT="$INSTALL_DIR/codex-switch-bin"

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

detect_shell_rc() {
  if [[ -n "${ZDOTDIR:-}" && -f "${ZDOTDIR}/.zshrc" ]]; then
    printf '%s\n' "${ZDOTDIR}/.zshrc"
    return 0
  fi

  if [[ -n "${SHELL:-}" ]]; then
    case "$SHELL" in
      */zsh)
        printf '%s\n' "$HOME/.zshrc"
        return 0
        ;;
      */bash)
        if [[ -f "$HOME/.bash_profile" ]]; then
          printf '%s\n' "$HOME/.bash_profile"
        else
          printf '%s\n' "$HOME/.bashrc"
        fi
        return 0
        ;;
    esac
  fi

  printf '%s\n' "$HOME/.profile"
}

ensure_path_line() {
  local rc_file="$1"
  local path_line='export PATH="$HOME/.local/bin:$PATH"'

  mkdir -p "$(dirname "$rc_file")"
  touch "$rc_file"

  if ! grep -Fq "$path_line" "$rc_file"; then
    {
      printf '\n# Added by codex-switch installer\n'
      printf '%s\n' "$path_line"
    } >> "$rc_file"
  fi
}

ensure_shell_wrapper() {
  local rc_file="$1"
  local begin_marker='# >>> codex-switch >>>'
  local end_marker='# <<< codex-switch <<<'
  local temp_file
  temp_file="$(mktemp)"

  mkdir -p "$(dirname "$rc_file")"
  touch "$rc_file"

  python3 - "$rc_file" "$temp_file" "$begin_marker" "$end_marker" <<'PY'
import sys
from pathlib import Path

rc_path = Path(sys.argv[1])
tmp_path = Path(sys.argv[2])
begin = sys.argv[3]
end = sys.argv[4]
text = rc_path.read_text() if rc_path.exists() else ""
lines = text.splitlines()
out = []
inside = False
for line in lines:
    if line == begin:
        inside = True
        continue
    if inside and line == end:
        inside = False
        continue
    if not inside:
        out.append(line)
tmp_path.write_text("\n".join(out).rstrip() + ("\n" if out else ""))
PY
  mv "$temp_file" "$rc_file"

  cat >> "$rc_file" <<'EOF'
# >>> codex-switch >>>
codex-switch() {
  if [[ $# -eq 0 ]]; then
    command codex-switch-bin help
    return
  fi

  case "$1" in
    login|list|logout|skills|version|help|-h|--help|--version|-V)
      command codex-switch-bin "$@"
      ;;
    switch|use|activate)
      shift
      eval "$(command codex-switch-bin switch "$@")"
      ;;
    off|deactivate)
      eval "$(command codex-switch-bin switch default)"
      ;;
    *)
      eval "$(command codex-switch-bin switch "$1")"
      ;;
  esac
}
# <<< codex-switch <<<
EOF
}

main() {
  [[ -f "$SOURCE_SCRIPT" ]] || die "cannot find $SOURCE_SCRIPT"

  mkdir -p "$INSTALL_DIR"
  chmod +x "$SOURCE_SCRIPT"
  ln -sf "$SOURCE_SCRIPT" "$TARGET_SCRIPT"

  local rc_file
  rc_file="$(detect_shell_rc)"

  if [[ "$INSTALL_DIR" == "$HOME/.local/bin" ]]; then
    ensure_path_line "$rc_file"
  fi
  ensure_shell_wrapper "$rc_file"

  printf 'Installed codex-switch backend to %s\n' "$TARGET_SCRIPT"
  printf 'Shell config updated: %s\n' "$rc_file"
  printf 'Run this once to refresh your shell:\n'
  printf '  source %q\n' "$rc_file"
}

main "$@"
