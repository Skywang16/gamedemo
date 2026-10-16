PYTHON ?= python3
VENV := .venv/bin
GODOT := ./tools/godot.sh

.PHONY: setup import run editor art maps content check test test-ui audio package clean

setup:
	$(PYTHON) -m venv .venv
	$(VENV)/python -m pip install -r requirements-dev.txt

import:
	$(GODOT) --headless --editor --import

run:
	./launch.command

editor: import
	$(GODOT) --editor

audio:
	$(VENV)/python tools/audio/build_audio.py

art:
	$(VENV)/python tools/build_art.py

maps:
	$(VENV)/python tools/world/build_maps.py
	$(VENV)/python tools/world/build_map_doc.py

content: maps
	$(VENV)/python tools/content/build_story.py
	$(VENV)/python tools/content/build_routines_doc.py
	$(VENV)/python tools/content/build_cast_doc.py
	$(VENV)/python tools/content/build_story_doc.py

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
	$(GODOT) --headless --script res://tests/motion_tests.gd
	$(GODOT) --headless --script res://tests/world_tests.gd
	$(GODOT) --headless --script res://tests/rules_tests.gd
	$(GODOT) --headless --script res://tests/story_tests.gd
	$(GODOT) --headless --script res://tests/combat_tests.gd
	$(GODOT) --headless --audio-driver Dummy --script res://tests/interior_tests.gd -- --save-dir=user://interior-test-$$(uuidgen)
	$(GODOT) --headless --audio-driver Dummy --script res://tests/scale_smoke.gd -- --save-dir=user://ui-test-scale-$$(uuidgen)

test-ui: import
	$(GODOT) --script res://tests/ui_smoke.gd -- --save-dir=user://ui-test-$$(uuidgen)
	$(GODOT) --script res://tests/ui_regressions.gd -- --save-dir=user://ui-test-regression-$$(uuidgen)
	$(GODOT) --script res://tests/animation_smoke.gd -- --save-dir=user://ui-test-animation-$$(uuidgen)
	$(GODOT) --script res://tests/weather_smoke.gd -- --save-dir=user://ui-test-weather-$$(uuidgen)
	$(GODOT) --script res://tests/story_smoke.gd -- --save-dir=user://ui-test-story-$$(uuidgen)
	$(GODOT) --script res://tests/map_tour.gd -- --save-dir=user://ui-test-tour-$$(uuidgen)

package:
	$(VENV)/python tools/package_macos.py "$$($(GODOT) --print-path)"

clean:
	rm -rf build .godot .ruff_cache
