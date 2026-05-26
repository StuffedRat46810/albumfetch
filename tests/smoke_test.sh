#!/bin/sh
set -e

echo "--- Starting Smoke Test on $(cat /etc/os-release | grep '^PRETTY_NAME' | cut -d= -f2 | tr -d '\"') ---"

# 1. Setup the strict environment
# albumfetch requires its config specifically in the user's home directory
mkdir -p ~/.config/albumfetch
echo '{}' >~/.config/albumfetch/config.json

# 2. Execution Tests directly from the mounted build directory
echo "Testing --help flag..."
/app/zig-out/bin/albumfetch --help >/dev/null

echo "Testing default execution..."
/app/zig-out/bin/albumfetch >/dev/null

echo "--- Smoke Test Passed! ---"
