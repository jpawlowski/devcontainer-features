#!/usr/bin/env bash

# Description: Run the tests for the specified features

set -e
current_dir=$(pwd)
trap 'cd "$current_dir"' EXIT
cd "$(dirname "$0")/.." || exit 1

# Run the tests
if [ -n "$1" ]; then
  devcontainer features test --features "$@" | tee /dev/null
else
  devcontainer features test | tee /dev/null
fi
