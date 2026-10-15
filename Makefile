PYTHON ?= python3
VENV := .venv/bin
GODOT := ./tools/godot.sh

.PHONY: setup import run editor art maps check test test-ui package clean

setup:
	$(PYTHON) -m venv .venv
	$(VENV)/python -m pip install -r requirements-dev.txt

import:
	$(GODOT) --headless --editor --import

run:
	./launch.command

editor: import
	$(GODOT) --editor

art:
	$(VENV)/python tools/build_art.py

maps:
	$(VENV)/python tools/world/build_layouts.py

check:
	$(VENV)/gdformat --check src tests
	$(VENV)/ruff check tools
	$(VENV)/ruff format --check tools
	sh -n launch.command tools/godot.sh

test: import
	$(GODOT) --headless --script res://tests/test_runner.gd
	$(GODOT) --headless --script res://tests/chapter_tests.gd
	$(GODOT) --headless --script res://tests/calendar_tests.gd
	$(GODOT) --headless --script res://tests/settings_tests.gd

test-ui: import
	$(GODOT) --script res://tests/ui_smoke.gd -- --save-dir=user://ui-test-$$(uuidgen)
	$(GODOT) --script res://tests/animation_smoke.gd -- --save-dir=user://ui-test-animation-$$(uuidgen)

package:
	$(VENV)/python tools/package_macos.py "$$($(GODOT) --print-path)"

clean:
	rm -rf build .godot .ruff_cache
