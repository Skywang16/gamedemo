#!/bin/sh
# Resolve the local engine once for launch, editor, tests and packaging.
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
if [ -n "${GODOT_BIN:-}" ]; then
  engine_bin="$GODOT_BIN"
elif command -v godot >/dev/null 2>&1; then
  engine_bin=$(command -v godot)
elif command -v godot4 >/dev/null 2>&1; then
  engine_bin=$(command -v godot4)
elif [ -x "$HOME/Applications/Godot.app/Contents/MacOS/Godot" ]; then
  engine_bin="$HOME/Applications/Godot.app/Contents/MacOS/Godot"
else
  engine_bin=/Applications/Godot.app/Contents/MacOS/Godot
fi
if [ ! -x "$engine_bin" ]; then
  printf '%s\n' '请安装 Godot 4.7.2 标准版，或用 GODOT_BIN 指定可执行文件的绝对路径。' >&2
  exit 1
fi
if [ "${1:-}" = '--print-path' ]; then
  printf '%s\n' "$engine_bin"
  exit 0
fi
exec "$engine_bin" --path "$project_dir" "$@"
