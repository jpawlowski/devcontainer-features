#!/usr/bin/env bash

# Description: Run the autogenerated tests for the specified features

set -e
current_dir=$(pwd)
trap 'cd "$current_dir"' EXIT
cd "$(dirname "$0")/.." || exit 1

# Run the tests
if [ -n "$1" ]; then
  devcontainer features test --skip-scenarios --skip-duplicated --features "$@" | tee /dev/null
else
  devcontainer features test --skip-scenarios --skip-duplicated | tee /dev/null
fi
