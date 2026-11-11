#!/usr/bin/env python3
# Aero7 build script
# Bundles modular source under src/ into dist/Win7UI.lua using Darklua.

import os
import subprocess
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
CONFIG_PATH = os.path.join(PROJECT_ROOT, ".darklua.json")
ENTRY_PATH = os.path.join(PROJECT_ROOT, "src", "init.lua")
DIST_DIR = os.path.join(PROJECT_ROOT, "dist")
OUTPUT_PATH = os.path.join(DIST_DIR, "Win7UI.lua")
TEMP_PATH = os.path.join(DIST_DIR, ".bundle.tmp.lua")

HEADER = """--!nonstrict
-- Aero7 - Windows 7 Aero Glass UI Library for Roblox
-- Repository: https://github.com/tobureinhardt/Time-machine
-- License: MIT

"""

def build():
    if not os.path.isfile(ENTRY_PATH):
        sys.exit(f"error: entry file not found at {ENTRY_PATH}")
    if not os.path.isfile(CONFIG_PATH):
        sys.exit(f"error: darklua config not found at {CONFIG_PATH}")

    os.makedirs(DIST_DIR, exist_ok=True)

    cmd = ["darklua", "process", "-c", CONFIG_PATH, ENTRY_PATH, TEMP_PATH]
    res = subprocess.run(cmd, cwd=PROJECT_ROOT, capture_output=True, text=True)
    if res.returncode != 0:
        sys.exit(f"darklua bundle failed:\n{res.stderr}")

    with open(TEMP_PATH, "r", encoding="utf-8") as f:
        bundled_code = f.read()

    if os.path.isfile(TEMP_PATH):
        os.remove(TEMP_PATH)

    final_output = HEADER + bundled_code
    with open(OUTPUT_PATH, "w", encoding="utf-8") as f:
        f.write(final_output)

    line_count = final_output.count("\n") + 1
    size_bytes = len(final_output.encode("utf-8"))
    print(f"[build] output: {OUTPUT_PATH}")
    print(f"[build] size: {size_bytes} bytes, {line_count} lines")

if __name__ == "__main__":
    build()
