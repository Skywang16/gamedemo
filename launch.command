#!/bin/sh
set -eu
project_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
"$project_dir/tools/godot.sh" --headless --editor --import
exec "$project_dir/tools/godot.sh" "$@"
