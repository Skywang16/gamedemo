#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
if [ -n "${GODOT_BIN:-}" ] && [ -x "$GODOT_BIN" ]; then
  engine_bin="$GODOT_BIN"
elif [ -x "$project_dir/../../work/tools/Godot.app/Contents/MacOS/Godot" ]; then
  engine_bin="$project_dir/../../work/tools/Godot.app/Contents/MacOS/Godot"
elif [ -x /Applications/Godot.app/Contents/MacOS/Godot ]; then
  engine_bin=/Applications/Godot.app/Contents/MacOS/Godot
elif command -v godot >/dev/null 2>&1; then
  engine_bin=$(command -v godot)
else
  printf '%s\n' '请先安装 Godot 4.7.2 标准版，或用 GODOT_BIN 指定 Godot 可执行文件。'
  exit 1
fi
"$engine_bin" --headless --path "$project_dir" --editor --import
exec "$engine_bin" --path "$project_dir" "$@"
