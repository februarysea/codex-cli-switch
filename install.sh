#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="$SCRIPT_DIR/bin/codex-switch"
INSTALL_DIR="${CODEX_SWITCH_INSTALL_DIR:-$HOME/.local/bin}"
TARGET_SCRIPT="$INSTALL_DIR/codex-switch"

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

  printf 'Installed codex-switch to %s\n' "$TARGET_SCRIPT"
  printf 'Shell config updated: %s\n' "$rc_file"
  printf 'Run this once to refresh your shell:\n'
  printf '  source %q\n' "$rc_file"
}

main "$@"
